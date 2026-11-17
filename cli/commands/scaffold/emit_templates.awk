# ## Overview
# Zero-PowerShell AWK template extractor for cli/commands/scaffold/scaffold.cmd.
# Parses write_component_file heredocs from scaffold.sh, applies SCAF_* environment
# substitutions literally, and emits LF (.sh/.json/.md) or CRLF (.cmd) files.
#
# ## Usage
# gawk -f cli/commands/scaffold/emit_templates.awk cli/commands/scaffold/scaffold.sh

BEGIN {
  BINMODE = 3
  cdir = ENVIRON["COMP_TARGET_DIR"]
  if (cdir == "") cdir = ENVIRON["_CDIR"]
  is_service = tolower(ENVIRON["SCAF_IS_SERVICE"])
  force_write = (ENVIRON["SCAF_FORCE"] == "1") ? 1 : 0
  def_ver = ENVIRON["SCAF_DEFAULT_VERSION"]
  if (def_ver == "") def_ver = "latest"

  n_keys = 0
  add_map("__SCAF_NAME__", ENVIRON["SCAF_NAME"])
  add_map("__SCAF_TITLE__", ENVIRON["SCAF_TITLE"])
  add_map("__SCAF_CATEGORY__", ENVIRON["SCAF_CATEGORY"])
  add_map("__SCAF_DESCRIPTION__", ENVIRON["SCAF_DESCRIPTION"])
  add_map("__SCAF_BINARY_NAME__", ENVIRON["SCAF_BINARY_NAME"])
  add_map("__SCAF_INSTALL_METHOD__", ENVIRON["SCAF_INSTALL_METHOD"])
  add_map("__SCAF_DEFAULT_VERSION__", def_ver)
  add_map("__SCAF_VERSION_SCHEME__", ENVIRON["SCAF_VERSION_SCHEME"])
  add_map("__SCAF_GITHUB_REPO__", ENVIRON["SCAF_GITHUB_REPO"])
  add_map("__SCAF_TAG_PREFIX__", ENVIRON["SCAF_TAG_PREFIX"])
  add_map("__SCAF_URL_UNIX__", ENVIRON["SCAF_URL_UNIX"])
  add_map("__SCAF_URL_WINDOWS__", ENVIRON["SCAF_URL_WINDOWS"])
  add_map("__SCAF_RELEASES_URL__", ENVIRON["SCAF_RELEASES_URL"])
  add_map("__SCAF_STRIP_COMPONENTS__", ENVIRON["SCAF_STRIP_COMPONENTS"])
  add_map("__SCAF_SRC_URL__", ENVIRON["SCAF_URL_UNIX"])
  add_map("__SCAF_SRC_LANG__", ENVIRON["SCAF_SRC_LANG"])
  add_map("__SCAF_SRC_BUILD_SYS__", ENVIRON["SCAF_SRC_BUILD_SYS"])
  add_map("__SCAF_SRC_FALLBACK_VER__", ENVIRON["SCAF_SRC_FALLBACK_VER"])
  add_map("__SCAF_TEST_CMD__", ENVIRON["SCAF_TEST_CMD"])
  add_map("__COMP_PREFIX__", ENVIRON["COMP_PREFIX"])

  in_block = 0
  skip_block = 0
  out_path = ""
  is_crlf = 0
}

function add_map(k, v) {
  n_keys++
  map_k[n_keys] = k
  map_v[n_keys] = v
}

function replace_all(str, pat, rep,    idx, plen) {
  plen = length(pat)
  if (plen == 0) return str
  while ((idx = index(str, pat)) > 0) {
    str = substr(str, 1, idx - 1) rep substr(str, idx + plen)
  }
  return str
}

function file_exists(p,    rc, dummy) {
  rc = (getline dummy < p)
  if (rc >= 0) {
    close(p)
    return 1
  }
  return 0
}

{
  sub(/\r$/, "", $0)
  if (!in_block) {
    if (match($0, /^[[:space:]]*write_component_file "\$\{_comp_dir\}\/[A-Za-z0-9_.-]+" [01] [01] << 'EOF'$/)) {
      hdr = $0
      sub(/^[[:space:]]*write_component_file "\$\{_comp_dir\}\//, "", hdr)
      fname = hdr
      sub(/".*$/, "", fname)
      rest = hdr
      sub(/^[^"]+" [01] /, "", rest)
      is_crlf = (substr(rest, 1, 1) == "1") ? 1 : 0
      in_block = 1
      skip_block = 0
      if ((fname == "service.sh" || fname == "service.cmd") && is_service != "true") {
        skip_block = 1
      } else {
        sep_dir = (index(cdir, "\\") > 0) ? "\\" : "/"
        out_path = cdir sep_dir fname
        if (!force_write && file_exists(out_path)) {
          skip_block = 1
        } else {
          printf "" > out_path
        }
      }
    }
    next
  }

  if ($0 == "EOF") {
    if (!skip_block && out_path != "") {
      close(out_path)
    }
    in_block = 0
    skip_block = 0
    out_path = ""
    next
  }

  if (!skip_block) {
    line = $0
    for (i = 1; i <= n_keys; i++) {
      if (index(line, map_k[i]) > 0) {
        line = replace_all(line, map_k[i], map_v[i])
      }
    }
    if (is_crlf) {
      printf "%s\r\n", line >> out_path
    } else {
      printf "%s\n", line >> out_path
    }
  }
}
