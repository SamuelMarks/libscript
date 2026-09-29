#!/bin/sh
# ## Overview
# Dynamic LibScript Component Catalog Engine for the live installer.
# Scans all 260+ components across the LibScript ecosystem, generates indexed JSON catalogs,
# and outputs interactive searchable tables for TUI and GUI selection menus.
#
# ## Usage
# Execute this script to list, search, or export the component catalog:
#   ./_lib/package-managers/msi-rs/preloader/catalog.sh [--json | --search <term> | --category <name> | --clean-base]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

MODE="table"
SEARCH_TERM=""
FILTER_CAT=""

# ## show_help
# Displays usage instructions and supported query options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s
' "Scans and displays the dynamic LibScript component catalog."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --json                 Output full component catalog in JSON format."
  printf '%s
' "  --search <term>        Filter components matching search keyword."
  printf '%s
' "  --category <name>      Filter components within specified category."
  printf '%s
' "  --clean-base           Specify zero components (install clean base OS only)."
  printf '%s
' "  --help, -h, /?, -?     Show this help message."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      MODE="json"
      shift
      ;;
    --search)
      SEARCH_TERM="${2:-}"
      shift 2
      ;;
    --category)
      FILTER_CAT="${2:-}"
      shift 2
      ;;
    --clean-base)
      printf '[]
'
      exit 0
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# ## scan_components
# Discovers components by scanning manifest.json files across _lib.
scan_components() {
  _mode="$1"
  _search="$2"
  _cat="$3"

  set +f
  if [ "$_mode" = "json" ]; then
    printf '[\n'
    _first=1
    for manifest in "${REPO_ROOT}"/_lib/*/*/manifest.json; do
      [ -f "$manifest" ] || continue
      _cname=$(awk -F'"' '/"name":/ {print $4; exit}' "$manifest" || true)
      _ccat=$(awk -F'"' '/"category":/ {print $4; exit}' "$manifest" || true)
      _ctitle=$(awk -F'"' '/"title":/ {print $4; exit}' "$manifest" || true)
      _cdesc=$(awk -F'"' '/"description":/ {print $4; exit}' "$manifest" || true)

      if [ -n "$_cat" ] && [ "$_cat" != "$_ccat" ]; then
        continue
      fi

      if [ -n "$_search" ]; then
        if ! printf '%s %s %s\n' "$_cname" "$_ctitle" "$_cdesc" | grep -qi "$_search"; then
          continue
        fi
      fi

      [ "$_first" -eq 0 ] && printf ',\n'
      printf '  {"name": "%s", "category": "%s", "title": "%s", "description": "%s"}' \
             "$_cname" "$_ccat" "${_ctitle:-$_cname}" "${_cdesc:-No description}"
      _first=0
    done
    printf '\n]\n'
  else
    printf '%-20s %-18s %-40s\n' "COMPONENT" "CATEGORY" "DESCRIPTION"
    printf '%-20s %-18s %-40s\n' "--------------------" "------------------" "----------------------------------------"
    for manifest in "${REPO_ROOT}"/_lib/*/*/manifest.json; do
      [ -f "$manifest" ] || continue
      _cname=$(awk -F'"' '/"name":/ {print $4; exit}' "$manifest" || true)
      _ccat=$(awk -F'"' '/"category":/ {print $4; exit}' "$manifest" || true)
      _cdesc=$(awk -F'"' '/"description":/ {print $4; exit}' "$manifest" || true)

      if [ -n "$_cat" ] && [ "$_cat" != "$_ccat" ]; then
        continue
      fi

      if [ -n "$_search" ]; then
        if ! printf '%s %s\n' "$_cname" "$_cdesc" | grep -qi "$_search"; then
          continue
        fi
      fi

      printf '%-20s %-18s %-40s\n' "$_cname" "$_ccat" "${_cdesc:-No description}"
    done
  fi
  set -f
}

scan_components "$MODE" "$SEARCH_TERM" "$FILTER_CAT"
exit 0
