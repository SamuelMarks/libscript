#!/bin/sh
# ## Overview
# Generates markdown documentation for the libscript codebase.
# ## Usage
# Execute this script to rebuild the markdown documentation.
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ] || [ "${1:-}" = '/?' ] || [ "${1:-}" = '-?' ]; then
  printf '%s\n' "Usage: $(basename -- "${THIS_FILE}")"
  printf '%s\n' 'Generates markdown documentation for the libscript codebase.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
  exit 0
fi
: "${ROOT_DIR:=${LIBSCRIPT_ROOT_DIR}}"

if [ -f "${ROOT_DIR}/_lib/languages/nodejs/env.sh" ]; then
  _gmd_saved_this="${THIS_FILE:-}"
  _gmd_saved_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="${ROOT_DIR}/_lib/languages/nodejs/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  unset SCRIPT_NAME || true
  THIS_FILE="$_gmd_saved_this"
  SCRIPT_DIR="$_gmd_saved_dir"
  unset _gmd_saved_this _gmd_saved_dir || true
fi

if ! command -v jq >/dev/null 2>&1 || [ "$(printf '{"ok":1}' | jq -r '.ok' 2>/dev/null || true)" != '1' ]; then
  printf '[WARN] Functional jq binary not found on PATH; skipping README.md table regeneration.\n' >&2
  exit 0
fi

# ## normalize_markdown_section
# Normalizes a Markdown table or list stream so Prettier column-padding and blank-line differences are ignored when checking if semantic content changed.
normalize_markdown_section() {
  awk '
  {
    gsub(/\r/, "")
    line = $0
    sub(/^[ \t]+/, "", line)
    sub(/[ \t]+$/, "", line)
    if (line == "") {
      if (prose != "") { print prose; prose = "" }
      next
    }
    if (line ~ /^\|[ \t\-:|]+\|$/) {
      if (prose != "") { print prose; prose = "" }
      print "|---|---|---|---|"
      next
    }
    if (substr(line, 1, 1) == "|" && substr(line, length(line), 1) == "|") {
      if (prose != "") { print prose; prose = "" }
      inner = substr(line, 2, length(line) - 2)
      n = split(inner, cells, "|")
      out = "|"
      for (i = 1; i <= n; i++) {
        c = cells[i]
        sub(/^[ \t]+/, "", c)
        sub(/[ \t]+$/, "", c)
        out = out " " c " |"
      }
      print out
      next
    }
    if (line ~ /^[-*#><]/) {
      if (prose != "") { print prose; prose = "" }
      print line
      next
    }
    prose = (prose == "" ? line : prose " " line)
  }
  END {
    if (prose != "") { print prose; prose = "" }
  }'
}

# ## extract_marker_section
# Extracts lines strictly between the first occurrence of begin_marker and end_marker in a file.
extract_marker_section() {
  _file="$1"
  _begin="$2"
  _end="$3"
  awk -v b="$_begin" -v e="$_end" '
  BEGIN { inside = 0; done = 0 }
  index($0, b) > 0 && !done { inside = 1; next }
  index($0, e) > 0 && inside { inside = 0; done = 1; next }
  inside { print }
  ' "$_file"
}

GMD_WORK=$(libscript_make_tmpdir 'gmd')
trap 'rm -rf "$GMD_WORK"' EXIT INT TERM HUP

export ROOT_DIR
"${SCRIPT_DIR}/inject_markers.sh"

printf '%s\n' 'Generating markdown docs...'

modified_tmp="${GMD_WORK}/MODIFIED.TXT"
: > "$modified_tmp"
base_vars_tmp="${GMD_WORK}/BASE_VARS.TXT"
: > "$base_vars_tmp"
if [ -f "$ROOT_DIR/engine/schemas/base_vars.schema.json" ]; then
  jq -r '.properties | to_entries[] | "| `\(.key)` | \((.value.description // "") | gsub("[\r\n]+"; " ")) | `\(if (.value.default | type) == "array" and (.value.default | length) == 0 then "none" else (.value.default // "none") end)` | \([(.value.deprecated_aliases[]?), (.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$ROOT_DIR/engine/schemas/base_vars.schema.json" | sed 's/ |"$/ |/' > "$base_vars_tmp"
fi

PACK_ROWS_DIR="${GMD_WORK}/packs"
mkdir -p "$PACK_ROWS_DIR"
if [ -d "$ROOT_DIR/schemas/vars" ]; then
  set +f
  for _pk_f in "$ROOT_DIR/schemas/vars"/*.schema.json; do
    [ -f "$_pk_f" ] || continue
    _pk_n="${_pk_f##*/}"
    _pk_n="${_pk_n%.schema.json}"
    jq -r '.properties | to_entries[] | "| `\(.key)` | \((.value.description // "") | gsub("[\r\n]+"; " ")) | `\(if (.value.default | type) == "array" and (.value.default | length) == 0 then "none" else (.value.default // "none") end)` | \([(.value.deprecated_aliases[]?), (.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$_pk_f" | sed 's/ |"$/ |/' > "${PACK_ROWS_DIR}/${_pk_n}.rows"
  done
  set -f
fi

plat_tmp="${GMD_WORK}/PLAT.TXT"
printf '%s\n' '- Linux' '- macOS' '- Windows' > "$plat_tmp"
plat_norm=$(normalize_markdown_section < "$plat_tmp")

if [ -f "$ROOT_DIR/engine/common/README.md" ] && grep -q '<!-- BEGIN_VARS -->' "$ROOT_DIR/engine/common/README.md" && [ -s "$base_vars_tmp" ]; then
  common_vars_tmp="${GMD_WORK}/COMMON_VARS.TXT"
  printf '%s\n' '| Variable | Description | Default | Aliases/Examples |' '|---|---|---|---|' > "$common_vars_tmp"
  cat "$base_vars_tmp" >> "$common_vars_tmp"
  common_norm=$(normalize_markdown_section < "$common_vars_tmp")
  existing_common_norm=$(extract_marker_section "$ROOT_DIR/engine/common/README.md" '<!-- BEGIN_VARS -->' '<!-- END_VARS -->' | normalize_markdown_section)
  if [ "$common_norm" != "$existing_common_norm" ]; then
    common_readme_tmp="${GMD_WORK}/COMMON_README.TMP"
    awk -v vars="$common_vars_tmp" '
      BEGIN { in_vars = 0; done_vars = 0 }
      /<!-- BEGIN_VARS -->/ && !done_vars {
        print
        while ((getline line < vars) > 0) print line
        close(vars)
        in_vars = 1; done_vars = 1; next
      }
      /<!-- END_VARS -->/ && in_vars { in_vars = 0; print; next }
      !in_vars { print }
    ' "$ROOT_DIR/engine/common/README.md" > "$common_readme_tmp"
    mv "$common_readme_tmp" "$ROOT_DIR/engine/common/README.md"
    printf '%s\n' "$ROOT_DIR/engine/common/README.md" >> "$modified_tmp"
  fi
fi

# shellcheck disable=SC2329
# ## _gmd_shard_worker
# Regenerates README.md tables across a shard of component README paths.
_gmd_shard_worker() {
  _gsw_shard="$1"
  _gsw_mod="${_gsw_shard}.mod"
  : > "$_gsw_mod"
  _gsw_seq=0
  while IFS= read -r readme || [ -n "$readme" ]; do
    [ -n "$readme" ] || continue
    [ -f "$readme" ] || continue
    dir=$(dirname "$readme")
    case "$dir" in *engine/common*) continue ;; esac
    schema="$dir/vars.schema.json"
    [ -f "$schema" ] || continue

    _gsw_seq=$((_gsw_seq + 1))
    vars_tmp="${_gsw_shard}.v.${_gsw_seq}"
    printf '%s\n' '| Variable | Description | Default | Aliases/Examples |' '|---|---|---|---|' > "$vars_tmp"

    _pack_list=$(jq -r '."x-libscript-var-packs"[]? // empty' "$schema" 2>/dev/null || true)
    for _pk in $_pack_list; do
      if [ -f "${PACK_ROWS_DIR}/${_pk}.rows" ]; then
        cat "${PACK_ROWS_DIR}/${_pk}.rows" >> "$vars_tmp"
      fi
    done

    jq -r '.properties | to_entries[] | "| `\(.key)` | \((.value.description // "") | gsub("[\r\n]+"; " ")) | `\(if (.value.default | type) == "array" and (.value.default | length) == 0 then "none" else (.value.default // "none") end)` | \([(.value.deprecated_aliases[]?), (.value.version_aliases[]?), (.value.examples[]?)] | join(", ")) |"' "$schema" | sed 's/ |"$/ |/' >> "$vars_tmp"

    case "$dir" in
      *_lib/*)
        cat <<'EOF_NOTE' >> "$vars_tmp"

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`, and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
EOF_NOTE
        ;;
    esac

    vars_norm=$(normalize_markdown_section < "$vars_tmp")
    existing_vars_norm=$(extract_marker_section "$readme" '<!-- BEGIN_VARS -->' '<!-- END_VARS -->' | normalize_markdown_section)
    existing_plat_norm=$(extract_marker_section "$readme" '<!-- BEGIN_PLATFORMS -->' '<!-- END_PLATFORMS -->' | normalize_markdown_section)

    if [ "$vars_norm" != "$existing_vars_norm" ] || [ "$plat_norm" != "$existing_plat_norm" ]; then
      awk -v vars="$vars_tmp" -v plats="$plat_tmp" '
        BEGIN { in_vars = 0; in_plats = 0; done_vars = 0; done_plats = 0 }
        /<!-- BEGIN_VARS -->/ && !done_vars {
          print
          while ((getline line < vars) > 0) print line
          close(vars)
          in_vars = 1; done_vars = 1; next
        }
        /<!-- END_VARS -->/ && in_vars { in_vars = 0; print; next }
        /<!-- BEGIN_PLATFORMS -->/ && !done_plats {
          print
          while ((getline line < plats) > 0) print line
          close(plats)
          in_plats = 1; done_plats = 1; next
        }
        /<!-- END_PLATFORMS -->/ && in_plats { in_plats = 0; print; next }
        !in_vars && !in_plats { print }
      ' "$readme" > "${readme}.tmp"

      if ! cmp -s "${readme}.tmp" "$readme"; then
        mv "${readme}.tmp" "$readme"
        if command -v dos2unix >/dev/null 2>&1; then
          dos2unix -q "$readme" 2>/dev/null || true
        fi
        printf '%s\n' "$readme" >> "$_gsw_mod"
      else
        rm -f "${readme}.tmp"
      fi
    fi
    rm -f "$vars_tmp"
  done < "$_gsw_shard"
}

READMES_ALL="${GMD_WORK}/READMES.TXT"
if [ -d "${ROOT_DIR}/.git" ] && git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard '*README.md' \
    | grep -E '(_lib|app-servers|workloads/constellations|workloads/payloads|topologies|payloads)' \
    | awk -v root="${ROOT_DIR}/" '{ print root $0 }' > "$READMES_ALL" || true
else
  find "$ROOT_DIR" -type f -name 'README.md' | grep -E '(_lib|app-servers|workloads/constellations|workloads/payloads|topologies|payloads)' > "$READMES_ALL" || true
fi

if [ -s "$READMES_ALL" ]; then
  _gmd_sdir="${GMD_WORK}/shards"
  mkdir -p "$_gmd_sdir"
  _jobs=$(libscript_parallel_jobs)
  if [ "$_jobs" -gt 1 ]; then
    awk -v n="$_jobs" -v d="$_gmd_sdir" 'NF > 0 { idx = (c % n) + 1; c++; out = d "/S" idx ".TXT"; print $0 >> out; close(out) }' "$READMES_ALL"
    _pids=''
    _i=1
    while [ "$_i" -le "$_jobs" ]; do
      if [ -s "${_gmd_sdir}/S${_i}.TXT" ]; then
        ( _gmd_shard_worker "${_gmd_sdir}/S${_i}.TXT" ) &
        _pids="${_pids} $!"
      fi
      _i=$((_i + 1))
    done
    for _p in $_pids; do wait "$_p" || true; done
    set +f
    for _mf in "${_gmd_sdir}"/*.mod; do
      [ -s "$_mf" ] && cat "$_mf" >> "$modified_tmp"
    done
    set -f
  else
    _gmd_shard_worker "$READMES_ALL"
    [ -s "${READMES_ALL}.mod" ] && cat "${READMES_ALL}.mod" >> "$modified_tmp"
  fi
fi

# shellcheck disable=SC2329
# ## _run_prettier_batch
# Formats a batch of modified Markdown files using prettier.
_run_prettier_batch() {
  if command -v prettier >/dev/null 2>&1; then
    prettier --write "$@" >/dev/null 2>&1 || true
  elif [ -x "$ROOT_DIR/node_modules/.bin/prettier" ]; then
    "$ROOT_DIR/node_modules/.bin/prettier" --write "$@" >/dev/null 2>&1 || true
  elif command -v npx >/dev/null 2>&1; then
    npx --yes prettier --write "$@" >/dev/null 2>&1 || true
  fi
}

if [ -s "$modified_tmp" ]; then
  libscript_batch_exec "$modified_tmp" 40 _run_prettier_batch
fi

printf '%s\n' 'Done generating markdown docs.'
