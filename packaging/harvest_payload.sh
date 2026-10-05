#!/bin/sh
# ## Overview
# Harvests the complete LibScript repository into a deployment staging directory or WiX
# manifest fragment while strictly respecting .gitignore exclusion rules.
# Embeds the core execution engine, library recipes, stacks, CLIs, and utilities
# required for standalone, self-contained installation on target systems.
# Supports optional offline cache harvesting via `--include-cache <dir>` for air-gapped installers
# as well as direct arbitrary stage directory harvesting via `--source-dir <dir>`.
#
# ## Usage
# ./packaging/harvest_payload.sh [OPTIONS]
#
# Options:
#   --source-dir <dir>       Source directory to harvest files from directly
#   --output-dir <dir>       Target staging directory where harvested files will be copied
#   --manifest-file <path>   Path to output newline-delimited list of harvested relative paths
#   --wix-fragment <path>    Path to output WiX XML (<Fragment>) file with components and files
#   --component-group <id>   WiX ComponentGroup ID (default: LibscriptHarvestedComponents)
#   --directory-id <id>      WiX Directory ID for root of payload (default: LIBSCRIPT_FOLDER)
#   --root-dir <path>        Root directory of repository (default: auto-detected)
#   --include-cache <dir>    Include hydrated offline cache directory into payload
#   --include-msi            Allow harvesting of .msi installer packages into payload
#   --help, -h               Show this help text

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SOURCE_DIR=""
OUTPUT_DIR=""
MANIFEST_FILE=""
WIX_FRAGMENT=""
COMPONENT_GROUP="LibscriptHarvestedComponents"
DIRECTORY_ID="LIBSCRIPT_FOLDER"
ROOT_DIR="${LIBSCRIPT_ROOT_DIR}"
INCLUDE_CACHE=""
INCLUDE_MSI=0

# ## show_help
# Prints usage and parameter documentation.
show_help() {
  printf 'Usage: %s [OPTIONS]\n\n' "$(basename "$THIS_FILE")"
  printf 'Options:\n'
  printf '  --source-dir <dir>       Source directory to harvest files from directly\n'
  printf '  --output-dir <dir>       Target staging directory for harvested files\n'
  printf '  --manifest-file <path>   Output file containing relative paths list\n'
  printf '  --wix-fragment <path>    Output file containing WiX XML fragment\n'
  printf '  --component-group <id>   WiX ComponentGroup ID (default: LibscriptHarvestedComponents)\n'
  printf '  --directory-id <id>      WiX Directory ID (default: LIBSCRIPT_FOLDER)\n'
  printf '  --root-dir <path>        Root repository directory\n'
  printf '  --include-cache <dir>    Include hydrated offline cache directory into payload\n'
  printf '  --include-msi            Allow harvesting of .msi installer packages\n'
  printf '  --help, -h               Show this help text\n'
  exit 0
}

# ## parse_args
# Parses CLI arguments and options.
while [ $# -gt 0 ]; do
  case "$1" in
    --source-dir|--stage-dir)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --source-dir=*|--stage-dir=*)
      SOURCE_DIR="${1#*=}"
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --manifest-file)
      MANIFEST_FILE="$2"
      shift 2
      ;;
    --wix-fragment)
      WIX_FRAGMENT="$2"
      shift 2
      ;;
    --component-group)
      COMPONENT_GROUP="$2"
      shift 2
      ;;
    --directory-id)
      DIRECTORY_ID="$2"
      shift 2
      ;;
    --root-dir)
      ROOT_DIR="$2"
      shift 2
      ;;
    --include-cache)
      INCLUDE_CACHE="$2"
      shift 2
      ;;
    --include-cache=*)
      INCLUDE_CACHE="${1#*=}"
      shift
      ;;
    --include-msi)
      INCLUDE_MSI=1
      shift
      ;;
    --help|-h|/?)
      show_help
      ;;
    *)
      printf '[ERROR] Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

# ## sanitize_wix_id
# Sanitizes arbitrary path strings into valid WiX Id tokens (alphanumeric and underscores).
# shellcheck disable=SC2329
sanitize_wix_id() {
  _val="$1"
  printf '%s' "$_val" | tr -c 'A-Za-z0-9_' '_'
}

TMP_LIST="$(mktemp "${TMPDIR:-/tmp}/harvest_files.XXXXXX")"
TMP_FILTERED="$(mktemp "${TMPDIR:-/tmp}/harvest_filtered.XXXXXX")"
trap 'rm -f "$TMP_LIST" "$TMP_FILTERED"' EXIT INT TERM

# Gather files list
if [ -n "${SOURCE_DIR}" ]; then
  if [ ! -d "${SOURCE_DIR}" ]; then
    printf '[ERROR] Source directory does not exist: %s\n' "${SOURCE_DIR}" >&2
    exit 1
  fi
  _source_real=$(cd -- "${SOURCE_DIR}" && pwd)
  ROOT_DIR="${_source_real}"
  cd "${_source_real}"
  find . -type f | sed 's|^\./||' > "${TMP_LIST}"
elif command -v git >/dev/null 2>&1 && [ -d "${ROOT_DIR}/.git" ]; then
  cd "${ROOT_DIR}"
  git ls-files -c -o --exclude-standard > "${TMP_LIST}"
else
  cd "${ROOT_DIR}"
  find . -type f | sed 's|^\./||' | while read -r _f; do
    case "$_f" in
      .git/*|.github/*|.githooks/*|.vagrant/*|tests_tmp/*|dist/*|build/*|node_modules/*|*kubernetes-the-hard-way*) continue ;;
      *.tmp|*.log|*.ppm|*.bak|*.swp|*.tar.gz|*.zip|*.7z|*.wixobj|*.wxs|*.pruned) continue ;;
      *)
        if [ "$INCLUDE_MSI" -eq 0 ]; then
          case "$_f" in *.msi) continue ;; esac
        fi
        printf '%s\n' "$_f"
        ;;
    esac
  done > "${TMP_LIST}"
fi

# Filter standard files and strictly exclude any cache directory in the base repo
while IFS= read -r _rel || [ -n "$_rel" ]; do
  [ -z "$_rel" ] && continue
  [ -f "${ROOT_DIR}/${_rel}" ] || continue

  if [ -n "${SOURCE_DIR}" ]; then
    case "$_rel" in
      .git*|.vagrant*|*.tmp|*.log|*.ppm|*.bak|*.swp|*.wixobj) continue ;;
      *)
        if [ "$INCLUDE_MSI" -eq 0 ]; then
          case "$_rel" in *.msi) continue ;; esac
        fi
        printf '%s\n' "$_rel" >> "${TMP_FILTERED}"
        ;;
    esac
  else
    case "$_rel" in
      .git*|.vagrant*|tests_tmp/*|dist/*|build/*|tmp/*|node_modules/*) continue ;;
      */.git/*|*/.git|*/.github/*|*/.githooks/*|*/.vagrant/*|*/tests_tmp/*|*/dist/*|*/build/*|*/tmp/*|*/node_modules/*) continue ;;
      cache/*|*/cache/*) continue ;;
      *.tmp|*.log|*.ppm|*.bak|*.swp|*.wixobj) continue ;;
      *.msi)
        [ "$INCLUDE_MSI" -eq 1 ] && printf '%s\n' "$_rel" >> "${TMP_FILTERED}"
        continue
        ;;
      packaging/screenshots/release_test/*) continue ;;
      *) printf '%s\n' "$_rel" >> "${TMP_FILTERED}" ;;
    esac
  fi
done < "${TMP_LIST}"

# If --include-cache is specified, harvest the offline cache files
if [ -n "${INCLUDE_CACHE}" ] && [ -d "${INCLUDE_CACHE}" ]; then
  _cache_real=$(cd -- "${INCLUDE_CACHE}" && pwd)
  find "$_cache_real" -type f | while read -r _cfile; do
    _rel_c="${_cfile#"${_cache_real}"/}"
    _rel_c="${_rel_c#./}"
    [ -z "$_rel_c" ] && continue
    printf 'cache/%s\n' "$_rel_c" >> "${TMP_FILTERED}"
  done
fi

# ## write_manifest
if [ -n "${MANIFEST_FILE}" ]; then
  _manifest_dir="$(dirname "${MANIFEST_FILE}")"
  [ -d "$_manifest_dir" ] || mkdir -p "$_manifest_dir"
  cp "${TMP_FILTERED}" "${MANIFEST_FILE}"
  printf '[INFO] Wrote manifest to: %s (%s files)
' "${MANIFEST_FILE}" "$(wc -l < "${MANIFEST_FILE}" | tr -d ' ')"
fi

# ## copy_payload
if [ -n "${OUTPUT_DIR}" ]; then
  [ -d "${OUTPUT_DIR}" ] || mkdir -p "${OUTPUT_DIR}"
  while IFS= read -r _rel || [ -n "$_rel" ]; do
    [ -z "$_rel" ] && continue
    if [ "${_rel#cache/}" != "$_rel" ] && [ -n "${INCLUDE_CACHE}" ]; then
      _cache_sub="${_rel#cache/}"
      _src="${INCLUDE_CACHE}/${_cache_sub}"
    else
      _src="${ROOT_DIR}/${_rel}"
    fi
    _dst="${OUTPUT_DIR}/${_rel}"
    _dst_dir="$(dirname "$_dst")"
    [ -d "$_dst_dir" ] || mkdir -p "$_dst_dir"
    cp -p "$_src" "$_dst"
  done < "${TMP_FILTERED}"
  printf '[INFO] Harvested files copied to: %s
' "${OUTPUT_DIR}"
fi

# ## generate_wix_fragment
if [ -n "${WIX_FRAGMENT}" ]; then
  _frag_dir="$(dirname "${WIX_FRAGMENT}")"
  [ -d "$_frag_dir" ] || mkdir -p "$_frag_dir"

  _tmp_wix="$(mktemp "${TMPDIR:-/tmp}/harvest_wix.XXXXXX")"
  awk -v "root=${ROOT_DIR}" -v "dir_id=${DIRECTORY_ID}" -v "comp_group=${COMPONENT_GROUP}" -v "inc_cache=${INCLUDE_CACHE:-}" '
function sanitize(s,   res) {
    res = s
    gsub(/[^a-zA-Z0-9_]/, "_", res)
    return res
}
function str_hash32(s, seed, mult, mod,   res, i, len, c) {
    res = seed
    len = length(s)
    for (i = 1; i <= len; i++) {
        c = ord[substr(s, i, 1)]
        res = (res * mult + c) % mod
    }
    return res
}
function make_hash(s,   h1, h2, h3, h4) {
    h1 = str_hash32(s, 5381, 33, 2147483647)
    h2 = str_hash32(s, 52711, 37, 2147483629)
    h3 = str_hash32(s, 7919, 31, 2147483587)
    h4 = str_hash32(s, 179424673, 41, 2147483579)
    return sprintf("%08x%08x%08x%08x", h1, h2, h3, h4)
}
function make_id(prefix, raw_path,   san, cand, max_pre, avail, trimmed, h) {
    san = sanitize(raw_path)
    cand = prefix san
    if (cand in used_ids && used_ids[cand] != raw_path) {
        cand = ""
    }
    if (cand != "" && length(cand) <= 72) {
        used_ids[cand] = raw_path
        return cand
    }
    h = make_hash(raw_path)
    max_pre = 72 - 32 - 1
    avail = max_pre - length(prefix)
    trimmed = (avail > 0) ? substr(san, 1, avail) : ""
    cand = prefix trimmed "_" h
    used_ids[cand] = raw_path
    return cand
}
function strip_root(path) {
    if (substr(path, 1, length(root) + 1) == root "/") {
        return substr(path, length(root) + 2)
    }
    if (path == root) return "."
    return path
}
BEGIN {
    for (i = 1; i <= 255; i++) ord[sprintf("%c", i)] = i
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    print "<Wix xmlns=\"http://schemas.microsoft.com/wix/2006/wi\">"
    print "  <Fragment>"
}
{
    files[NR] = $0
    n = split($0, parts, "/")
    cur = ""
    for (i = 1; i < n; i++) {
        prev = cur
        cur = (cur == "") ? parts[i] : (cur "/" parts[i])
        if (!(cur in dir_exists)) {
            dir_exists[cur] = 1
            dirs[++d_count] = cur
            dir_name[cur] = parts[i]
            dir_parent[cur] = prev
        }
    }
}
END {
    for (i = 1; i <= d_count; i++) {
        d = dirs[i]
        d_id = make_id("DIR_", d)
        p = dir_parent[d]
        p_id = (p == "") ? dir_id : make_id("DIR_", p)
        print "    <DirectoryRef Id=\"" p_id "\">"
        print "      <Directory Id=\"" d_id "\" Name=\"" dir_name[d] "\" />"
        print "    </DirectoryRef>"
    }

    for (i = 1; i <= NR; i++) {
        f = files[i]
        if (f == "") continue
        c_id = make_id("CMP_H_", f)
        f_id = make_id("FIL_H_", f)
        n = split(f, parts, "/")
        dir_path = ""
        for (j = 1; j < n; j++) {
            dir_path = (dir_path == "") ? parts[j] : (dir_path "/" parts[j])
        }
        target_dir = (dir_path == "") ? dir_id : make_id("DIR_", dir_path)

        if (inc_cache != "" && substr(f, 1, 6) == "cache/") {
            src = inc_cache "/" substr(f, 7)
        } else {
            src = root "/" f
        }
        src = strip_root(src)

        disk_id = "1"
        if (substr(f, 1, 15) == "cache/runtimes/") {
            disk_id = "2"
        } else if (substr(f, 1, 16) == "cache/databases/") {
            disk_id = "3"
        } else if (substr(f, 1, 15) == "cache/codebase/" || substr(f, 1, 13) == "cache/wheels/" || substr(f, 1, 10) == "cache/npm/") {
            disk_id = "4"
        }

        print "    <DirectoryRef Id=\"" target_dir "\">"
        print "      <Component Id=\"" c_id "\" Guid=\"*\">"
        print "        <File Id=\"" f_id "\" Source=\"" src "\" KeyPath=\"yes\" DiskId=\"" disk_id "\" />"
        print "      </Component>"
        print "    </DirectoryRef>"
    }

    print "    <ComponentGroup Id=\"" comp_group "\">"
    for (i = 1; i <= NR; i++) {
        f = files[i]
        if (f == "") continue
        if (inc_cache != "" && substr(f, 1, 6) == "cache/") continue
        c_id = make_id("CMP_H_", f)
        print "      <ComponentRef Id=\"" c_id "\" />"
    }
    print "    </ComponentGroup>"

    if (inc_cache != "") {
        print "    <ComponentGroup Id=\"LibscriptOfflineCacheComponents\">"
        for (i = 1; i <= NR; i++) {
            f = files[i]
            if (f == "") continue
            if (substr(f, 1, 6) == "cache/") {
                c_id = make_id("CMP_H_", f)
                print "      <ComponentRef Id=\"" c_id "\" />"
            }
        }
        print "    </ComponentGroup>"
    }

    print "  </Fragment>"
    print "</Wix>"
}
' "${TMP_FILTERED}" > "$_tmp_wix"

  mv "$_tmp_wix" "${WIX_FRAGMENT}"
  printf '[INFO] Generated WiX XML fragment: %s\n' "${WIX_FRAGMENT}"
fi

if [ "$(wc -l < "${TMP_FILTERED}" | tr -d ' ')" -eq 0 ]; then
  printf '[ERROR] Harvested 0 files. Payload is empty.\n' >&2
  exit 1
fi

printf '[PASS] Harvesting complete (%s files identified).
' "$(wc -l < "${TMP_FILTERED}" | tr -d ' ')"
exit 0
