#!/bin/sh
# ## Overview
# Universal dependency license harvester and bundler for LibScript installers.
# Discovers all packaged dependencies, extracts and validates their legal terms,
# and generates formatted plain-text and Rich Text Format (.rtf) license agreements
# alongside an indexed licenses_manifest.json for WiX, Inno Setup, and NSIS installers.
#
# ## Usage
# ./packaging/harvest_licenses.sh <TARGET_DIR_OR_PLAN> [OPTIONS]
#
# Options:
#   --out-dir <dir>       Output directory for harvested license assets (default: ./licenses)
#   --format <type>       Format to generate: rtf, txt, or all (default: all)
#   --force               Regenerate licenses even if stamp file exists
#   --help, -h            Show this help text

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

TARGET_INPUT=""
OUT_DIR=""
FORMAT="all"
FORCE=0

# ## show_help
# Prints usage and options documentation to standard output.
show_help() {
  printf 'Usage: %s <TARGET_DIR_OR_PLAN> [OPTIONS]

' "$(basename "$THIS_FILE")"
  printf 'Options:
'
  printf '  --out-dir <dir>   Output directory for harvested license assets (default: <target>/licenses)
'
  printf '  --format <type>   Format to generate: rtf, txt, or all (default: all)
'
  printf '  --force           Regenerate licenses even if stamp file exists
'
  printf '  --help, -h        Show this help text
'
  exit 0
}

# ## parse_cli
# Parses command-line flags and parameters without using eval.
while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --format)
      FORMAT="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --help|-h)
      show_help
      ;;
    -*)
      printf '[ERROR] Unknown option: %s
' "$1" >&2
      exit 1
      ;;
    *)
      if [ -z "$TARGET_INPUT" ]; then
        TARGET_INPUT="$1"
        shift
      else
        printf '[ERROR] Unexpected argument: %s
' "$1" >&2
        exit 1
      fi
      ;;
  esac
done

if [ -z "$TARGET_INPUT" ]; then
  printf '[ERROR] Missing required target directory or execution plan argument.
' >&2
  printf 'Run %s --help for usage.
' "$(basename "$THIS_FILE")" >&2
  exit 1
fi

# Resolve absolute path to TARGET_INPUT
if [ -d "$TARGET_INPUT" ]; then
  TARGET_PATH=$(cd -- "$TARGET_INPUT" && pwd)
elif [ -f "$TARGET_INPUT" ]; then
  _dir=$(cd -- "$(dirname -- "$TARGET_INPUT")" && pwd)
  _file=$(basename -- "$TARGET_INPUT")
  TARGET_PATH="$_dir/$_file"
else
  printf '[ERROR] Target input does not exist: %s
' "$TARGET_INPUT" >&2
  exit 1
fi

if [ -z "$OUT_DIR" ]; then
  if [ -d "$TARGET_PATH" ]; then
    OUT_DIR="$TARGET_PATH/licenses"
  else
    OUT_DIR="$(dirname -- "$TARGET_PATH")/licenses"
  fi
fi

# Check stamp file for idempotency
STAMP_FILE="$OUT_DIR/.stamp.licenses_harvested"
if [ "$FORCE" -eq 0 ] && [ -f "$STAMP_FILE" ] && [ -f "$OUT_DIR/licenses_manifest.json" ]; then
  printf '[INFO] Licenses already harvested and up-to-date at: %s
' "$OUT_DIR"
  exit 0
fi

mkdir -p "$OUT_DIR"
CANONICAL_LICENSES_DIR="${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/packaging/licenses"
if [ ! -d "$CANONICAL_LICENSES_DIR" ] && [ -d "${LIBSCRIPT_ROOT_DIR}/cc0-assets/libscript/packaging/licenses" ]; then
  CANONICAL_LICENSES_DIR="${LIBSCRIPT_ROOT_DIR}/cc0-assets/libscript/packaging/licenses"
fi

# Temporary workspace for JSON assembly
TMP_DIR="${OUT_DIR}/.tmp_harvest_$$"
mkdir -p "$TMP_DIR"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

# ## resolve_spdx_file
# Locates the best matching canonical license file for a given SPDX identifier.
resolve_spdx_file() {
  _spdx="$1"
  _candidate=""

  # Exact match
  if [ -f "$CANONICAL_LICENSES_DIR/${_spdx}.txt" ]; then
    printf '%s
' "$CANONICAL_LICENSES_DIR/${_spdx}.txt"
    return 0
  fi

  # Check individual tokens separated by whitespace, OR, AND
  for _token in $_spdx; do
    case "$_token" in
      OR|AND|\(|\))
        continue
        ;;
      *)
        if [ -f "$CANONICAL_LICENSES_DIR/${_token}.txt" ]; then
          printf '%s
' "$CANONICAL_LICENSES_DIR/${_token}.txt"
          return 0
        fi
        ;;
    esac
  done

  # Fallback to MIT if unknown
  if [ -f "$CANONICAL_LICENSES_DIR/MIT.txt" ]; then
    printf '%s
' "$CANONICAL_LICENSES_DIR/MIT.txt"
    return 0
  fi

  return 1
}

# ## convert_to_rtf
# Idempotently converts a plain-text license file to a WiX-compatible RTF document.
convert_to_rtf() {
  _src_txt="$1"
  _dst_rtf="$2"
  _title="$3"
  _spdx="$4"

  {
    printf '{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Courier;}}\\fs20\n'
    printf '{\\b Software License Agreement: %s}\\par\n' "$_title"
    printf '{\\b SPDX License Identifier: %s}\\par\n' "$_spdx"
    printf '%s\n' '--------------------------------------------------------------------------------\par'
    sed 's/\\/\\\\/g; s/{/\\{/g; s/}/\\}/g; s/$/\\par/' "$_src_txt"
    printf '}\n'
  } > "$_dst_rtf"
}

# Collect list of packages to harvest
ITEMS_JSON="$TMP_DIR/items.json"
printf '[]' > "$ITEMS_JSON"

# 1. Check if target is execution-plan.json
if [ -f "$TARGET_PATH" ] && case "$TARGET_PATH" in *.json) true ;; *) false ;; esac; then
  if grep -q '"stages"' "$TARGET_PATH" 2>/dev/null; then
    # Extract tasks from execution plan
    jq '[.stages[].tasks[] | {name: .name, component: .component, license: (.license // "MIT")}]' "$TARGET_PATH" > "$ITEMS_JSON"
  fi
fi

# 2. Check if packaging.json with bundled_licenses exists
PKG_JSON=""
if [ -d "$TARGET_PATH" ] && [ -f "$TARGET_PATH/packaging.json" ]; then
  PKG_JSON="$TARGET_PATH/packaging.json"
elif [ -f "$TARGET_PATH" ] && [ "$(basename "$TARGET_PATH")" = "packaging.json" ]; then
  PKG_JSON="$TARGET_PATH"
fi

if [ -n "$PKG_JSON" ] && [ -f "$PKG_JSON" ]; then
  # Extract bundled_licenses if declared
  _has_bundled=$(jq 'if .branding.bundled_licenses then 1 else 0 end' "$PKG_JSON" 2>/dev/null || printf '0')
  if [ "$_has_bundled" = "1" ]; then
    jq '.branding.bundled_licenses | map({
      name: .component,
      title: .title,
      spdx: .spdx_id,
      license_file: (.license_file // ""),
      mandatory: (if .mandatory == false then false else true end)
    })' "$PKG_JSON" > "$ITEMS_JSON"
  fi
fi

# 3. If still empty, inspect manifest.json in target directory
if [ "$(jq 'length' "$ITEMS_JSON" 2>/dev/null || printf '0')" = "0" ]; then
  MAN_JSON=""
  if [ -d "$TARGET_PATH" ] && [ -f "$TARGET_PATH/manifest.json" ]; then
    MAN_JSON="$TARGET_PATH/manifest.json"
  elif [ -f "$TARGET_PATH" ] && [ "$(basename "$TARGET_PATH")" = "manifest.json" ]; then
    MAN_JSON="$TARGET_PATH"
  fi

  if [ -n "$MAN_JSON" ] && [ -f "$MAN_JSON" ]; then
    # Add top-level component itself
    _self_name=$(jq -r '.name // "app"' "$MAN_JSON")
    _self_title=$(jq -r '.title // .name // "Application"' "$MAN_JSON")
    _self_spdx=$(jq -r '.license // "Proprietary"' "$MAN_JSON")

    jq -n \
      --arg name "$_self_name" \
      --arg title "$_self_title" \
      --arg spdx "$_self_spdx" \
      '[{name: $name, title: $title, spdx: $spdx, mandatory: true}]' > "$ITEMS_JSON"

    # Add required components
    _reqs=$(jq -r '.requires[]? // empty' "$MAN_JSON")
    for req in $_reqs; do
      _req_man="${LIBSCRIPT_ROOT_DIR}/_lib/${req}/manifest.json"
      if [ -f "$_req_man" ]; then
        _req_name=$(jq -r '.name' "$_req_man")
        _req_title=$(jq -r '.title // .name' "$_req_man")
        _req_spdx=$(jq -r '.license // "MIT"' "$_req_man")
        _req_lic_file=$(jq -r '.license_file // ""' "$_req_man")

        jq \
          --arg name "$_req_name" \
          --arg title "$_req_title" \
          --arg spdx "$_req_spdx" \
          --arg lic_file "$_req_lic_file" \
          '. += [{name: $name, title: $title, spdx: $spdx, license_file: $lic_file, mandatory: true}]' \
          "$ITEMS_JSON" > "$TMP_DIR/tmp_items.json" && mv "$TMP_DIR/tmp_items.json" "$ITEMS_JSON"
      fi
    done
  fi
fi

# Process harvested items and build output manifest
FINAL_LICENSES_JSON="$TMP_DIR/final_licenses.json"
printf '[]' > "$FINAL_LICENSES_JSON"

_item_count=$(jq 'length' "$ITEMS_JSON")
printf '[INFO] Harvesting licenses for %s components...\n' "$_item_count"

_idx=0
while [ "$_idx" -lt "$_item_count" ]; do
  _name=$(jq -r ".[$_idx].name" "$ITEMS_JSON")
  _title=$(jq -r ".[$_idx].title // .[$_idx].name" "$ITEMS_JSON")
  _spdx=$(jq -r ".[$_idx].spdx // .[$_idx].license // \"MIT\"" "$ITEMS_JSON")
  _custom_file=$(jq -r ".[$_idx].license_file // \"\"" "$ITEMS_JSON")
  _mandatory=$(jq -r "if .[$_idx].mandatory == false then false else true end" "$ITEMS_JSON")

  # Normalize safe identifier
  _safe_id=$(printf '%s' "$_name" | tr -c 'a-zA-Z0-9_' '_')

  _txt_out="$OUT_DIR/${_safe_id}_license.txt"
  _rtf_out="$OUT_DIR/${_safe_id}_license.rtf"

  # Find license text source
  _src_file=""
  if [ -n "$_custom_file" ] && [ -f "$_custom_file" ]; then
    _src_file="$_custom_file"
  elif [ -n "$_custom_file" ] && [ -f "$LIBSCRIPT_ROOT_DIR/$_custom_file" ]; then
    _src_file="$LIBSCRIPT_ROOT_DIR/$_custom_file"
  elif [ -n "$_custom_file" ] && [ -f "$CANONICAL_LICENSES_DIR/$(basename "$_custom_file")" ]; then
    _src_file="$CANONICAL_LICENSES_DIR/$(basename "$_custom_file")"
  else
    _src_file=$(resolve_spdx_file "$_spdx" || printf '')
  fi

  if [ -n "$_src_file" ] && [ -f "$_src_file" ]; then
    # Header prepended text
    {
      printf '================================================================================\n'
      printf 'Software License Agreement: %s (%s)\n' "$_title" "$_name"
      printf 'SPDX License Identifier: %s\n' "$_spdx"
      printf '================================================================================\n\n'
      cat "$_src_file"
    } > "$_txt_out"
  else
    {
      printf '================================================================================\n'
      printf 'Software License Agreement: %s (%s)\n' "$_title" "$_name"
      printf 'SPDX License Identifier: %s\n' "$_spdx"
      printf '================================================================================\n\n'
      printf 'This component is distributed under the terms of the %s license.\n' "$_spdx"
      printf 'Please refer to upstream source documentation for full legal text.\n'
    } > "$_txt_out"
  fi

  # Generate requested formats
  case "$FORMAT" in
    txt)
      rm -f "$_rtf_out"
      ;;
    rtf)
      convert_to_rtf "$_txt_out" "$_rtf_out" "$_title" "$_spdx"
      rm -f "$_txt_out"
      ;;
    *)
      convert_to_rtf "$_txt_out" "$_rtf_out" "$_title" "$_spdx"
      ;;
  esac

  # Relative paths for manifest
  _rel_txt="licenses/${_safe_id}_license.txt"
  _rel_rtf="licenses/${_safe_id}_license.rtf"

  jq \
    --arg name "$_safe_id" \
    --arg title "$_title" \
    --arg spdx "$_spdx" \
    --arg rtf "$_rel_rtf" \
    --arg txt "$_rel_txt" \
    --arg prop "LICENSE_ACCEPTED_${_safe_id}" \
    --argjson mand "$_mandatory" \
    '. += [{
      name: $name,
      title: $title,
      spdx: $spdx,
      rtf_file: $rtf,
      txt_file: $txt,
      property_id: $prop,
      mandatory: $mand
    }]' "$FINAL_LICENSES_JSON" > "$TMP_DIR/tmp_final.json" && mv "$TMP_DIR/tmp_final.json" "$FINAL_LICENSES_JSON"

  _idx=$((_idx + 1))
done

# Write licenses_manifest.json
jq -n \
  --arg target "$TARGET_PATH" \
  --arg count "$_item_count" \
  --slurpfile items "$FINAL_LICENSES_JSON" \
  '{
    target: $target,
    count: ($count | tonumber),
    licenses: $items[0]
  }' > "$OUT_DIR/licenses_manifest.json"

# Write idempotency stamp
touch "$STAMP_FILE"

printf '[INFO] Successfully harvested %s licenses into %s
' "$_item_count" "$OUT_DIR"
printf '[INFO] Manifest written to %s/licenses_manifest.json
' "$OUT_DIR"
