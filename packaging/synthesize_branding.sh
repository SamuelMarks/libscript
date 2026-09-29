#!/bin/sh
# ## Overview
# Universal branding synthesizer generating 24-bit BMP banners, multi-resolution ICO,
# and aggregated RTF EULA for Windows Installer (MSI) packages based on packaging.json
# branding_palette declarations.
#
# ## Usage
#   ./packaging/synthesize_branding.sh <path_to_packaging.json_or_dir> [--output-dir DIR]
#
# ## Exit Codes
#   0 - Branding synthesized successfully
#   1 - Synthesis failed or invalid packaging specification

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
export DIR="${SCRIPT_DIR}"

TARGET_SPEC="${1:-}"
if [ -z "$TARGET_SPEC" ]; then
  printf '[ERROR] No stack directory or packaging.json specified
' >&2
  exit 1
fi
shift

OUTPUT_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --output-dir|-o)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      OUTPUT_DIR="$1"
      shift
      ;;
  esac
done

# Resolve packaging.json path
PKG_JSON="$TARGET_SPEC"
if [ -d "$TARGET_SPEC" ]; then
  PKG_JSON="${TARGET_SPEC}/packaging.json"
fi

if [ ! -f "$PKG_JSON" ]; then
  printf '[ERROR] packaging.json not found at: %s
' "$PKG_JSON" >&2
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$(dirname "$PKG_JSON")/assets"
fi

mkdir -p "$OUTPUT_DIR"

# Extract colors and metadata via python3 or fallback awk
_branding_props=$(python3 -c "
import json
with open('$PKG_JSON') as f:
    d = json.load(f)
name = d.get('name', 'app')
title = d.get('title', name)
p = d.get('branding_palette', {})
primary = p.get('primary_color', '#0078D4').lstrip('#')
secondary = p.get('secondary_color', '#2B88D8').lstrip('#')
dark = p.get('dark_color', '#101820').lstrip('#')
eula_comps = ','.join(p.get('eula_components', [title]))

print(f'APP_NAME={name}')
print(f'APP_TITLE={title}')
print(f'PRIMARY_HEX={primary}')
print(f'SECONDARY_HEX={secondary}')
print(f'DARK_HEX={dark}')
print(f'EULA_COMPS={eula_comps}')
")

while IFS='=' read -r _key _val; do
  case "$_key" in
    APP_NAME) APP_NAME="$_val" ;;
    APP_TITLE) APP_TITLE="$_val" ;;
    PRIMARY_HEX) PRIMARY_HEX="$_val" ;;
    SECONDARY_HEX) SECONDARY_HEX="$_val" ;;
    DARK_HEX) DARK_HEX="$_val" ;;
    EULA_COMPS) EULA_COMPS="$_val" ;;
  esac
done << EOF
$_branding_props
EOF

# Convert HEX to RGB decimal
hex_to_r() { printf '%d' "0x$(printf '%s' "$1" | cut -c1-2)"; }
hex_to_g() { printf '%d' "0x$(printf '%s' "$1" | cut -c3-4)"; }
hex_to_b() { printf '%d' "0x$(printf '%s' "$1" | cut -c5-6)"; }

PR_R=$(hex_to_r "$PRIMARY_HEX"); PR_G=$(hex_to_g "$PRIMARY_HEX"); PR_B=$(hex_to_b "$PRIMARY_HEX")
SC_R=$(hex_to_r "$SECONDARY_HEX"); SC_G=$(hex_to_g "$SECONDARY_HEX"); SC_B=$(hex_to_b "$SECONDARY_HEX")
DK_R=$(hex_to_r "$DARK_HEX"); DK_G=$(hex_to_g "$DARK_HEX"); DK_B=$(hex_to_b "$DARK_HEX")

# ## generate_side_banner
# Synthesizes 164x312 24-bit uncompressed RGB BMP side splash banner.
generate_side_banner() {
  _out="$1"
  awk -v pr_r="$PR_R" -v pr_g="$PR_G" -v pr_b="$PR_B" -v sc_r="$SC_R" -v sc_g="$SC_G" -v sc_b="$SC_B" -v dk_r="$DK_R" -v dk_g="$DK_G" -v dk_b="$DK_B" '
  function write_u16(val) { printf "%c%c", val % 256, int(val / 256) % 256 }
  function write_u32(val) { printf "%c%c%c%c", val % 256, int(val / 256) % 256, int(val / 65536) % 256, int(val / 16777216) % 256 }
  BEGIN {
    w = 164; h = 312
    row_bytes = w * 3
    pad = (4 - (row_bytes % 4)) % 4
    img_size = (row_bytes + pad) * h
    file_size = 54 + img_size

    printf "BM"
    write_u32(file_size)
    write_u16(0); write_u16(0)
    write_u32(54)
    write_u32(40)
    write_u32(w); write_u32(h)
    write_u16(1); write_u16(24)
    write_u32(0); write_u32(img_size)
    write_u32(2835); write_u32(2835)
    write_u32(0); write_u32(0)

    for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) {
        if (y < 6) {
          # Bottom accent strip
          printf "%c%c%c", pr_b, pr_g, pr_r
        } else if ((y >= 88 && y <= 90 && x >= 16 && x <= 148) || (y >= 192 && y <= 194 && x >= 16 && x <= 148)) {
          # Secondary accent line
          printf "%c%c%c", sc_b, sc_g, sc_r
        } else {
          # Dark background
          printf "%c%c%c", dk_b, dk_g, dk_r
        }
      }
      for (p = 0; p < pad; p++) printf "%c", 0
    }
  }' > "$_out"
  printf '[OK] Generated side banner: %s (164x312)\n' "$_out"
}

# ## generate_top_banner
# Synthesizes 493x58 24-bit uncompressed RGB BMP top header banner.
generate_top_banner() {
  _out="$1"
  awk -v pr_r="$PR_R" -v pr_g="$PR_G" -v pr_b="$PR_B" '
  function write_u16(val) { printf "%c%c", val % 256, int(val / 256) % 256 }
  function write_u32(val) { printf "%c%c%c%c", val % 256, int(val / 256) % 256, int(val / 65536) % 256, int(val / 16777216) % 256 }
  BEGIN {
    w = 493; h = 58
    row_bytes = w * 3
    pad = (4 - (row_bytes % 4)) % 4
    img_size = (row_bytes + pad) * h
    file_size = 54 + img_size

    printf "BM"
    write_u32(file_size)
    write_u16(0); write_u16(0)
    write_u32(54)
    write_u32(40)
    write_u32(w); write_u32(h)
    write_u16(1); write_u16(24)
    write_u32(0); write_u32(img_size)
    write_u32(2835); write_u32(2835)
    write_u32(0); write_u32(0)

    for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) {
        if (y == 0) {
          printf "%c%c%c", pr_b, pr_g, pr_r
        } else {
          printf "%c%c%c", 255, 255, 255
        }
      }
      for (p = 0; p < pad; p++) printf "%c", 0
    }
  }' > "$_out"
  printf '[OK] Generated top banner: %s (493x58)
' "$_out"
}

# ## generate_ico
# Synthesizes multi-resolution application icon (.ico).
generate_ico() {
  _out="$1"
  awk -v pr_r="$PR_R" -v pr_g="$PR_G" -v pr_b="$PR_B" -v sc_r="$SC_R" -v sc_g="$SC_G" -v sc_b="$SC_B" -v dk_r="$DK_R" -v dk_g="$DK_G" -v dk_b="$DK_B" '
  function write_u16(val) { printf "%c%c", val % 256, int(val / 256) % 256 }
  function write_u32(val) { printf "%c%c%c%c", val % 256, int(val / 256) % 256, int(val / 65536) % 256, int(val / 16777216) % 256 }
  BEGIN {
    sizes[0] = 256; sizes[1] = 48; sizes[2] = 32; sizes[3] = 16
    num_sizes = 4
    printf "%c%c%c%c%c%c", 0, 0, 1, 0, num_sizes, 0

    offset = 6 + num_sizes * 16
    for (i = 0; i < num_sizes; i++) {
      s = sizes[i]
      w_byte = (s >= 256) ? 0 : s
      h_byte = (s >= 256) ? 0 : s
      row_bytes = s * 4
      img_size = row_bytes * s
      mask_row = int((s + 31) / 32) * 4
      mask_size = mask_row * s
      blob_size = 40 + img_size + mask_size

      printf "%c%c%c%c", w_byte, h_byte, 0, 0
      write_u16(1)
      write_u16(32)
      write_u32(blob_size)
      write_u32(offset)
      offset += blob_size
    }

    for (i = 0; i < num_sizes; i++) {
      s = sizes[i]
      row_bytes = s * 4
      img_size = row_bytes * s
      mask_row = int((s + 31) / 32) * 4
      mask_size = mask_row * s

      write_u32(40); write_u32(s); write_u32(s * 2)
      write_u16(1); write_u16(32); write_u32(0)
      write_u32(img_size + mask_size)
      write_u32(0); write_u32(0); write_u32(0); write_u32(0)

      pad = int(s * 0.08)
      cx = s * 0.5; cy = s * 0.5
      r_in = s * 0.25

      for (y = 0; y < s; y++) {
        for (x = 0; x < s; x++) {
          if (x >= pad && x < (s - pad) && y >= pad && y < (s - pad)) {
            dx = x - cx; dy = y - cy
            dist = sqrt(dx * dx + dy * dy)
            if (dist < r_in) {
              printf "%c%c%c%c", pr_b, pr_g, pr_r, 255
            } else {
              printf "%c%c%c%c", dk_b, dk_g, dk_r, 255
            }
          } else {
            printf "%c%c%c%c", 0, 0, 0, 0
          }
        }
      }
      for (m = 0; m < mask_size; m++) printf "%c", 0
    }
  }' > "$_out"
  printf '[OK] Generated multi-res icon: %s
' "$_out"
}

# ## generate_eula
# Synthesizes Rich Text Format (.rtf) EULA.
generate_eula() {
  _out="$1"
  cat << EOF > "$_out"
tf1\ansi\deff0 {\fonttbl {\f0 Arial;}}\fs20
{\b $APP_TITLE End User License Agreement}\par
\par
This deployment package provisions $APP_TITLE along with its declared service dependencies.\par
\par
Licensed components:\par
$EULA_COMPS\par
\par
By continuing the installation, you agree to comply with all applicable open-source and commercial licensing terms.\par
}
EOF
  printf '[OK] Generated EULA: %s
' "$_out"
}

generate_side_banner "${OUTPUT_DIR}/banner_side.bmp"
generate_top_banner "${OUTPUT_DIR}/banner_top.bmp"
generate_ico "${OUTPUT_DIR}/app.ico"
generate_eula "${OUTPUT_DIR}/license.rtf"

printf '[SUCCESS] Branding synthesis complete in %s
' "$OUTPUT_DIR"
