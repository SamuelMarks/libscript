#!/bin/sh
# ## Overview
# Harvests the complete LibScript repository into a deployment staging directory or WiX
# manifest fragment while strictly respecting .gitignore exclusion rules.
# Embeds the core execution engine, library recipes, stacks, CLIs, and utilities
# required for standalone, self-contained installation on target systems.
# Supports optional offline cache harvesting via `--include-cache <dir>` for air-gapped installers.
#
# ## Usage
# ./packaging/harvest_payload.sh [OPTIONS]
#
# Options:
#   --output-dir <dir>       Target staging directory where harvested files will be copied
#   --manifest-file <path>   Path to output newline-delimited list of harvested relative paths
#   --wix-fragment <path>    Path to output WiX XML (<Fragment>) file with components and files
#   --component-group <id>   WiX ComponentGroup ID (default: LibscriptHarvestedComponents)
#   --directory-id <id>      WiX Directory ID for root of payload (default: LIBSCRIPT_FOLDER)
#   --root-dir <path>        Root directory of repository (default: auto-detected)
#   --include-cache <dir>    Include hydrated offline cache directory into payload
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

OUTPUT_DIR=""
MANIFEST_FILE=""
WIX_FRAGMENT=""
COMPONENT_GROUP="LibscriptHarvestedComponents"
DIRECTORY_ID="LIBSCRIPT_FOLDER"
ROOT_DIR="${LIBSCRIPT_ROOT_DIR}"
INCLUDE_CACHE=""

# ## show_help
# Prints usage and parameter documentation.
show_help() {
  printf 'Usage: %s [OPTIONS]

' "$(basename "$THIS_FILE")"
  printf 'Options:
'
  printf '  --output-dir <dir>       Target staging directory for harvested files
'
  printf '  --manifest-file <path>   Output file containing relative paths list
'
  printf '  --wix-fragment <path>    Output file containing WiX XML fragment
'
  printf '  --component-group <id>   WiX ComponentGroup ID (default: LibscriptHarvestedComponents)
'
  printf '  --directory-id <id>      WiX Directory ID (default: LIBSCRIPT_FOLDER)
'
  printf '  --root-dir <path>        Root repository directory
'
  printf '  --include-cache <dir>    Include hydrated offline cache directory into payload
'
  printf '  --help, -h               Show this help text
'
  exit 0
}

# ## parse_args
# Parses CLI arguments and options.
while [ $# -gt 0 ]; do
  case "$1" in
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
    --help|-h|/?)
      show_help
      ;;
    *)
      printf '[ERROR] Unknown argument: %s
' "$1" >&2
      exit 1
      ;;
  esac
done

# ## sanitize_wix_id
# Sanitizes arbitrary path strings into valid WiX Id tokens (alphanumeric and underscores).
sanitize_wix_id() {
  _val="$1"
  printf '%s' "$_val" | tr '/\.:- ' '______' | tr -cd 'A-Za-z0-9_'
}

TMP_LIST="$(mktemp "${TMPDIR:-/tmp}/harvest_files.XXXXXX")"
TMP_FILTERED="$(mktemp "${TMPDIR:-/tmp}/harvest_filtered.XXXXXX")"
trap 'rm -f "$TMP_LIST" "$TMP_FILTERED"' EXIT INT TERM

# Gather files list
cd "${ROOT_DIR}"
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
  git ls-files -c -o --exclude-standard > "${TMP_LIST}"
else
  find . -type f | sed 's|^\./||' | while read -r _f; do
    case "$_f" in
      .git/*|.github/*|.githooks/*|.vagrant/*|tests_tmp/*|dist/*|build/*|node_modules/*) continue ;;
      *.tmp|*.log|*.ppm|*.bak|*.swp|*.tar.gz|*.zip|*.7z|*.msi|*.wixobj|*.wxs) continue ;;
      *) printf '%s
' "$_f" ;;
    esac
  done > "${TMP_LIST}"
fi

# Filter standard files and strictly exclude any cache directory in the base repo
while IFS= read -r _rel || [ -n "$_rel" ]; do
  [ -z "$_rel" ] && continue
  [ -f "${ROOT_DIR}/${_rel}" ] || continue

  case "$_rel" in
    .git*|.vagrant*|tests_tmp/*|dist/*|build/*|node_modules/*) continue ;;
    */.git/*|*/.git|*/.github/*|*/.githooks/*|*/.vagrant/*|*/tests_tmp/*|*/dist/*|*/build/*|*/node_modules/*) continue ;;
    cache/*|*/cache/*) continue ;;
    *.tmp|*.log|*.ppm|*.bak|*.swp|*.msi|*.wixobj) continue ;;
    packaging/screenshots/release_test/*) continue ;;
    *) printf '%s
' "$_rel" >> "${TMP_FILTERED}" ;;
  esac
done < "${TMP_LIST}"

# If --include-cache is specified, harvest the offline cache files
if [ -n "${INCLUDE_CACHE}" ] && [ -d "${INCLUDE_CACHE}" ]; then
  _cache_real=$(cd -- "${INCLUDE_CACHE}" && pwd)
  find "$_cache_real" -type f | while read -r _cfile; do
    _rel_c="${_cfile#${_cache_real}/}"
    _rel_c="${_rel_c#./}"
    [ -z "$_rel_c" ] && continue
    printf 'cache/%s
' "$_rel_c" >> "${TMP_FILTERED}"
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
  {
    printf '<?xml version="1.0" encoding="UTF-8"?>
'
    printf '<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
'
    printf '  <Fragment>
'

    # Build unique directory paths including all ancestors
    _dirs_tmp="$(mktemp "${TMPDIR:-/tmp}/harvest_dirs.XXXXXX")"
    while read -r _file || [ -n "$_file" ]; do
      _d="$(dirname "$_file")"
      while [ "$_d" != "." ] && [ "$_d" != "/" ] && [ -n "$_d" ]; do
        printf '%s\n' "$_d"
        _d="$(dirname "$_d")"
      done
    done < "${TMP_FILTERED}" | sort -u > "$_dirs_tmp"

    while read -r _d || [ -n "$_d" ]; do
      [ -z "$_d" ] && continue
      _d_id="DIR_$(sanitize_wix_id "$_d")"
      _parent="$(dirname "$_d")"
      if [ "$_parent" = "." ]; then
        _p_id="${DIRECTORY_ID}"
      else
        _p_id="DIR_$(sanitize_wix_id "$_parent")"
      fi
      _name="$(basename "$_d")"
      printf '    <DirectoryRef Id="%s">\n' "$_p_id"
      printf '      <Directory Id="%s" Name="%s" />\n' "$_d_id" "$_name"
      printf '    </DirectoryRef>\n'
    done < "$_dirs_tmp"
    rm -f "$_dirs_tmp"

    # Generate Components wrapped in DirectoryRef with partition DiskIds
    while IFS= read -r _rel || [ -n "$_rel" ]; do
      [ -z "$_rel" ] && continue
      _c_id="CMP_H_$(sanitize_wix_id "$_rel")"
      _f_id="FIL_H_$(sanitize_wix_id "$_rel")"
      _dir="$(dirname "$_rel")"
      if [ "$_dir" = "." ]; then
        _target_dir="${DIRECTORY_ID}"
      else
        _target_dir="DIR_$(sanitize_wix_id "$_dir")"
      fi
      if [ "${_rel#cache/}" != "$_rel" ] && [ -n "${INCLUDE_CACHE}" ]; then
        _cache_sub="${_rel#cache/}"
        _src="${INCLUDE_CACHE}/${_cache_sub}"
      else
        _src="${ROOT_DIR}/${_rel}"
      fi

      case "$_rel" in
        cache/runtimes/*) _disk_id="2" ;;
        cache/databases/*) _disk_id="3" ;;
        cache/codebase/*|cache/wheels/*|cache/npm/*) _disk_id="4" ;;
        *) _disk_id="1" ;;
      esac

      printf '    <DirectoryRef Id="%s">
' "$_target_dir"
      printf '      <Component Id="%s" Guid="*">
' "$_c_id"
      printf '        <File Id="%s" Source="%s" KeyPath="yes" DiskId="%s" />
' "$_f_id" "$_src" "$_disk_id"
      printf '      </Component>
'
      printf '    </DirectoryRef>
'
    done < "${TMP_FILTERED}"

    # Generate ComponentGroup containing ComponentRefs
    printf '    <ComponentGroup Id="%s">
' "${COMPONENT_GROUP}"
    while IFS= read -r _rel || [ -n "$_rel" ]; do
      [ -z "$_rel" ] && continue
      _c_id="CMP_H_$(sanitize_wix_id "$_rel")"
      printf '      <ComponentRef Id="%s" />
' "$_c_id"
    done < "${TMP_FILTERED}"
    printf '    </ComponentGroup>
'

    # If offline cache is harvested, generate dedicated LibscriptOfflineCacheComponents group
    if [ -n "${INCLUDE_CACHE}" ]; then
      printf '    <ComponentGroup Id="LibscriptOfflineCacheComponents">
'
      while IFS= read -r _rel || [ -n "$_rel" ]; do
        [ -z "$_rel" ] && continue
        case "$_rel" in
          cache/*)
            _c_id="CMP_H_$(sanitize_wix_id "$_rel")"
            printf '      <ComponentRef Id="%s" />
' "$_c_id"
            ;;
        esac
      done < "${TMP_FILTERED}"
      printf '    </ComponentGroup>
'
    fi

    printf '  </Fragment>
'
    printf '</Wix>
'
  } > "$_tmp_wix"

  mv "$_tmp_wix" "${WIX_FRAGMENT}"
  printf '[INFO] Generated WiX XML fragment: %s
' "${WIX_FRAGMENT}"
fi

printf '[PASS] Harvesting complete (%s files identified).
' "$(wc -l < "${TMP_FILTERED}" | tr -d ' ')"
exit 0
