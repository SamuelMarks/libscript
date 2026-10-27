#!/bin/sh
# ## Overview
# Verifies that all generated .msi GUI and post-install browser/desktop verification
# screenshots in ../cc0-assets/libscript exist, are non-empty, have valid PNG headers,
# match every .verification_screenshots[] item declared in <target_dir>/packaging.json,
# and are tightly cropped across all target OS directories.
#
# ## Usage
# ./devtools/verify_screenshots.sh [--target <name|dir|all>] [--dir <path>]

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

TARGET='all'
CC0_BASE="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript"

# ## show_help
# Displays usage instructions for verify_screenshots.sh.
show_help() {
  printf 'Usage: %s [--target <name|dir|all>] [--dir <path>]
' "$0"
  printf 'Validates PNG headers, file sizes, declared verification_screenshots, and cropped dimensions.
'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      TARGET="$2"
      shift 2
      ;;
    --target=*)
      TARGET="${1#*=}"
      shift
      ;;
    --dir)
      CC0_BASE="$2"
      shift 2
      ;;
    --dir=*)
      CC0_BASE="${1#*=}"
      shift
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

# ## check_single_png
# Validates a single PNG file for non-zero size, valid header, and cropped window dimensions.
check_single_png() {
  _png="$1"
  if [ ! -f "$_png" ]; then
    printf '[FAIL] Missing screenshot: %s
' "$_png" >&2
    return 1
  fi
  _size=$(wc -c < "$_png" | tr -d ' ')
  if [ "$_size" -lt 1000 ]; then
    printf '[FAIL] Screenshot too small (%s bytes): %s
' "$_size" "$_png" >&2
    return 1
  fi
  if command -v file >/dev/null 2>&1; then
    _file_info=$(file "$_png")
    case "$_file_info" in
      *"PNG image data"*)
        _dims=$(printf '%s
' "$_file_info" | sed -n 's/.*PNG image data, \([0-9]*\) x \([0-9]*\).*/\1 \2/p')
        if [ -n "$_dims" ]; then
          _w=$(printf '%s
' "$_dims" | awk '{print $1}')
          _h=$(printf '%s
' "$_dims" | awk '{print $2}')
          if [ "$_w" -ge 1280 ] && [ "$_h" -ge 800 ]; then
            printf '[FAIL] Uncropped full-desktop screenshot (%sx%s): %s
' "$_w" "$_h" "$_png" >&2
            return 1
          fi
          printf '[PASS] %s (%s bytes, cropped %sx%s)
' "$_png" "$_size" "$_w" "$_h"
          return 0
        fi
        ;;
      *)
        printf '[FAIL] Invalid PNG format: %s (%s)
' "$_png" "$_file_info" >&2
        return 1
        ;;
    esac
  fi
  printf '[PASS] %s (%s bytes)
' "$_png" "$_size"
  return 0
}

# ## verify_declared_schema_screenshots
# Verifies that every .verification_screenshots[] item declared in packaging.json exists across all 5 OS directories.
verify_declared_schema_screenshots() {
  _pkg_json="$1"
  _shots_dir="$2"
  [ -f "$_pkg_json" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  _ids=$(jq -r '.verification_screenshots[]?.id // empty' "$_pkg_json")
  [ -z "$_ids" ] && return 0
  _missing=0
  for _id in $_ids; do
    if [ ! -f "${_shots_dir}/${_id}.png" ]; then
      printf '[FAIL] Missing declared verification screenshot: %s/%s.png
' "$_shots_dir" "$_id" >&2
      _missing=$((_missing + 1))
    fi
    for _os in windows linux macos freebsd illumos; do
      if [ -d "${_shots_dir}/${_os}" ] && [ ! -f "${_shots_dir}/${_os}/${_id}.png" ]; then
        printf '[FAIL] Missing OS verification screenshot: %s/%s/%s.png
' "$_shots_dir" "$_os" "$_id" >&2
        _missing=$((_missing + 1))
      fi
    done
  done
  [ "$_missing" -eq 0 ]
}

# ## verify_target_dir
# Verifies all PNG files in a target screenshot directory and checks packaging.json declarations.
verify_target_dir() {
  _dir="$1"
  _pkg_json="${2:-}"
  if [ ! -d "$_dir" ]; then
    printf '[WARN] Screenshot directory not found: %s
' "$_dir" >&2
    return 1
  fi
  _list_file="${TMPDIR:-/tmp}/verify_png_list_$$"
  find "$_dir" -type f -name "*.png" | sort > "$_list_file"
  _count=0
  _fail=0
  while IFS= read -r _f; do
    if [ -n "$_f" ] && [ -f "$_f" ]; then
      _count=$((_count + 1))
      check_single_png "$_f" || _fail=$((_fail + 1))
    fi
  done < "$_list_file"
  rm -f "$_list_file"
  if [ -n "$_pkg_json" ] && [ -f "$_pkg_json" ]; then
    verify_declared_schema_screenshots "$_pkg_json" "$_dir" || _fail=$((_fail + 1))
  fi
  if [ "$_count" -eq 0 ]; then
    printf '[FAIL] Zero PNG files found in %s
' "$_dir" >&2
    return 1
  fi
  if [ "$_fail" -gt 0 ]; then
    printf '[FAIL] %s validation error(s) in %s
' "$_fail" "$_dir" >&2
    return 1
  fi
  printf '[OK] Verified %s cropped screenshots in %s
' "$_count" "$_dir"
  return 0
}

# ## find_packaging_json_for_name
# Resolves the packaging.json path for a given component name.
find_packaging_json_for_name() {
  _name="$1"
  _found=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 3 -maxdepth 3 -path "*/${_name}/packaging.json" | head -n 1)
  printf '%s
' "$_found"
}

if [ "$TARGET" = "all" ]; then
  _rc=0
  _pkgs=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 3 -maxdepth 3 -name "packaging.json" | sort)
  for _p in $_pkgs; do
    _name=$(basename "${_p%/packaging.json}")
    if [ -d "${CC0_BASE}/${_name}/screenshots" ]; then
      verify_target_dir "${CC0_BASE}/${_name}/screenshots" "$_p" || _rc=1
    fi
  done
  exit "$_rc"
else
  _tname=$(basename "$TARGET")
  _pkg=$(find_packaging_json_for_name "$_tname")
  verify_target_dir "${CC0_BASE}/${_tname}/screenshots" "$_pkg"
fi
