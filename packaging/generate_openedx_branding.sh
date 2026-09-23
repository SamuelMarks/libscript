#!/bin/sh
# ## Overview
# Generates official Open edX branded bitmaps, multi-resolution icons, and
# license agreements conforming to WiX MSI packaging specifications on the fly.
#
# ## Usage
# ./packaging/generate_openedx_branding.sh [--output-dir DIR]

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

# ## show_help
# Prints usage and help message.
show_help() {
  printf '%s
' "Usage: $(basename "$0") [--output-dir DIR]"
  printf '%s
' "Generates official Open edX branded assets for Windows Installer."
  exit 0
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
fi

# ## parse_args
# Parses CLI arguments for target output directory.
OUTPUT_DIR="${LIBSCRIPT_ROOT_DIR}/packaging/assets"
while [ $# -gt 0 ]; do
  case "$1" in
    --output-dir|-o)
      if [ $# -gt 1 ]; then
        OUTPUT_DIR="$2"
        shift 2
      else
        OUTPUT_DIR="$1"
        shift
      fi
      ;;
    *)
      OUTPUT_DIR="$1"
      shift
      ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

PS_SCRIPT="${SCRIPT_DIR}/generate_openedx_branding.ps1"

# Delegate to PowerShell if available
if command -v powershell.exe >/dev/null 2>&1; then
  WIN_PS_SCRIPT="$(cygpath -w "${PS_SCRIPT}" 2>/dev/null || printf '%s' "${PS_SCRIPT}")"
  WIN_OUT_DIR="$(cygpath -w "${OUTPUT_DIR}" 2>/dev/null || printf '%s' "${OUTPUT_DIR}")"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${WIN_PS_SCRIPT}" -OutputDir "${WIN_OUT_DIR}"
  exit $?
elif command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "${PS_SCRIPT}" -OutputDir "${OUTPUT_DIR}"
  exit $?
fi

# ## generate_side_banner_posix
# Pure POSIX awk generator for 164x312 24-bit RGB openedx_banner_side.bmp.
generate_side_banner_posix() {
  out_file="$1"
  awk '
  function write_u16(val) {
    printf "%c%c", val % 256, int(val / 256) % 256
  }
  function write_u32(val) {
    printf "%c%c%c%c", val % 256, int(val / 256) % 256, int(val / 65536) % 256, int(val / 16777216) % 256
  }
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

    # Bottom-up pixel rows
    for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) {
        if (y < 6) {
          # Bottom blue strip (BGR: 180, 117, 0)
          printf "%c%c%c", 180, 117, 0
        } else if ((y >= 88 && y <= 90 && x >= 16 && x <= 148) || (y >= 192 && y <= 194 && x >= 16 && x <= 148)) {
          # Blue horizontal accent lines
          printf "%c%c%c", 180, 117, 0
        } else {
          # Navy background (BGR: 62, 38, 0)
          printf "%c%c%c", 62, 38, 0
        }
      }
      for (p = 0; p < pad; p++) printf "%c", 0
    }
  }' > "$out_file"
  printf '[OK] Generated %s (164x312)
' "$out_file"
}

# ## generate_top_banner_posix
# Pure POSIX awk generator for 493x58 24-bit RGB openedx_banner_top.bmp.
generate_top_banner_posix() {
  out_file="$1"
  awk '
  function write_u16(val) {
    printf "%c%c", val % 256, int(val / 256) % 256
  }
  function write_u32(val) {
    printf "%c%c%c%c", val % 256, int(val / 256) % 256, int(val / 65536) % 256, int(val / 16777216) % 256
  }
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

    # Bottom-up pixel rows: row 0 is bottom line (LINE_GRAY: 210, 205, 200)
    for (y = 0; y < h; y++) {
      for (x = 0; x < w; x++) {
        if (y == 0) {
          printf "%c%c%c", 210, 205, 200
        } else {
          printf "%c%c%c", 255, 255, 255
        }
      }
      for (p = 0; p < pad; p++) printf "%c", 0
    }
  }' > "$out_file"
  printf '[OK] Generated %s (493x58)
' "$out_file"
}

# ## generate_icon_posix
# Pure POSIX awk generator for multi-resolution openedx.ico (256, 48, 32, 16).
generate_icon_posix() {
  out_file="$1"
  awk '
  function write_u16(val) {
    printf "%c%c", val % 256, int(val / 256) % 256
  }
  function write_u32(val) {
    printf "%c%c%c%c", val % 256, int(val / 256) % 256, int(val / 65536) % 256, int(val / 16777216) % 256
  }
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
      blob_sizes[i] = blob_size

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

      write_u32(40)
      write_u32(s)
      write_u32(s * 2)
      write_u16(1)
      write_u16(32)
      write_u32(0)
      write_u32(img_size + mask_size)
      write_u32(0); write_u32(0)
      write_u32(0); write_u32(0)

      pad = int(s * 0.05)
      cx = s * 0.5; cy = s * 0.5
      r_in = s * 0.2

      for (y = 0; y < s; y++) {
        for (x = 0; x < s; x++) {
          if (x >= pad && x < (s - pad) && y >= pad && y < (s - pad)) {
            dx = x - cx; dy = y - cy
            dist = sqrt(dx * dx + dy * dy)
            if (dist < r_in) {
              printf "%c%c%c%c", 180, 117, 0, 255
            } else {
              printf "%c%c%c%c", 62, 38, 0, 255
            }
          } else {
            printf "%c%c%c%c", 0, 0, 0, 0
          }
        }
      }

      for (m = 0; m < mask_size; m++) {
        printf "%c", 0
      }
    }
  }' > "$out_file"
  printf '[OK] Generated %s (multi-res ICO)
' "$out_file"
}

# ## generate_eula_posix
# Emits the RTF End User License Agreement file.
generate_eula_posix() {
  out_file="$1"
  cat << 'EOF' > "$out_file"
{\rtf1\ansi\deff0 {\fonttbl {\f0 Courier;}}\fs20
Open edX Community License Agreement\par
\par
This Open edX Windows deployment package is licensed under the terms of
the GNU Affero General Public License (AGPLv3) and respective dependency licenses.\par
\par
By proceeding with the installation, you agree to comply with all applicable terms.\par
}
EOF
  printf '[OK] Generated %s (RTF EULA)
' "$out_file"
}

generate_side_banner_posix "${OUTPUT_DIR}/openedx_banner_side.bmp"
generate_top_banner_posix "${OUTPUT_DIR}/openedx_banner_top.bmp"
generate_icon_posix "${OUTPUT_DIR}/openedx.ico"
generate_eula_posix "${OUTPUT_DIR}/openedx_eula.rtf"
