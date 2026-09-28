#!/bin/sh
# ## Overview
# Automates capturing and archiving high-resolution screenshots and terminal recordings
# of the live-CD/live-USB installer process (headless, TUI, and GUI kiosk modes)
# directly into the ../cc0-assets repository.
#
# ## Usage
# Execute this script to capture and synchronize installer screenshots:
#   ./devtools/capture_msi_live_screenshots.sh [--all | --mode <headless|tui|gui>]

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

CC0_ROOT="${REPO_ROOT}/../cc0-assets"
CC0_MSI_DIR="${CC0_ROOT}/msi-rs/screenshots"
CC0_LIVE_DIR="${CC0_ROOT}/libscript/live-installer/screenshots"
TEMP_DIR="${REPO_ROOT}/tests_tmp/live_screenshots_$$"

# ## show_help
# Displays usage and command-line options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [--all | --mode <headless|tui|gui>]"
  printf '%s
' "Captures and stores live installer screenshots into ../cc0-assets."
  printf '
'
  printf '%s
' "Modes:"
  printf '%s
' "  headless  - Capture headless transaction logs and disk operations"
  printf '%s
' "  tui       - Capture terminal user interface wizard steps"
  printf '%s
' "  gui       - Capture fullscreen kiosk graphical installer dialogs"
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --all                 Capture all 3 interaction modes (default)."
  printf '%s
' "  --mode <name>         Capture only the specified mode."
  printf '%s
' "  --help, -h, /?, -?    Show this help message."
}

# ## cleanup
# Removes temporary artifacts and staging directory.
# shellcheck disable=SC2329
cleanup() {
  rm -rf "${TEMP_DIR}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Ensure target directories exist
mkdir -p "${TEMP_DIR}"
if [ -d "${CC0_ROOT}" ]; then
  mkdir -p "${CC0_MSI_DIR}"
  mkdir -p "${CC0_LIVE_DIR}"
fi

# ## find_qemu_monitor
# Discovers the active QEMU monitor UNIX domain socket for the running Vagrant VM.
find_qemu_monitor() {
  target_os="$1"
  for _id_file in "${REPO_ROOT}/vagrant/${target_os}/.vagrant/machines"/*/qemu/id; do
    if [ -f "$_id_file" ]; then
      _id=$(cat "$_id_file")
      _sock="${HOME}/.vagrant.d/tmp/vagrant-qemu/${_id}/qemu_socket"
      if [ -S "$_sock" ]; then
        printf '%s
' "$_sock"
        return 0
      fi
    fi
  done
  return 1
}

# ## save_asset_image
# Converts raw PPM framebuffer dumps to PNG and copies to cc0-assets.
save_asset_image() {
  src_file="$1"
  asset_name="$2"
  out_png="${TEMP_DIR}/${asset_name}.png"

  if [ -f "$src_file" ]; then
    case "$src_file" in
      *.ppm)
        if command -v sips >/dev/null 2>&1; then
          sips -s format png "$src_file" --out "$out_png" >/dev/null 2>&1
        elif command -v magick >/dev/null 2>&1; then
          magick "$src_file" "$out_png" >/dev/null 2>&1
        fi
        ;;
      *.png)
        cp -f "$src_file" "$out_png"
        ;;
    esac
  fi

  if [ -f "$out_png" ]; then
    if [ -d "${CC0_MSI_DIR}" ]; then
      cp -f "$out_png" "${CC0_MSI_DIR}/${asset_name}.png"
    fi
    if [ -d "${CC0_LIVE_DIR}" ]; then
      cp -f "$out_png" "${CC0_LIVE_DIR}/${asset_name}.png"
    fi
    printf '[SAVED] ../cc0-assets: %s.png (%s bytes)
' "$asset_name" "$(wc -c < "$out_png" | tr -d ' ')"
  fi
}

# ## capture_framebuffer
# Triggers screendump on active QEMU monitor socket.
capture_framebuffer() {
  sock="$1"
  name="$2"
  ppm_path="${TEMP_DIR}/${name}.ppm"

  if [ -S "$sock" ]; then
    printf 'screendump %s
' "$ppm_path" | nc -U "$sock" >/dev/null 2>&1 || true
    sleep 1
    if [ -f "$ppm_path" ]; then
      save_asset_image "$ppm_path" "$name"
      rm -f "$ppm_path"
    fi
  fi
}

# ## capture_headless_mode
# Simulates and captures headless automated installation step screens.
capture_headless_mode() {
  printf '[CAPTURE] Recording Headless Installer flow...
'
  steps="live_headless_partitioning live_headless_install_linux live_headless_install_freebsd live_headless_install_illumos live_headless_preload_openedx live_headless_preload_wordpress"
  for step in $steps; do
    printf '          Capturing %s...
' "$step"
    # In live Vagrant environments, QEMU console screendump is captured
    vm_sock=$(find_qemu_monitor "debian-13" 2>/dev/null || true)
    if [ -n "$vm_sock" ]; then
      capture_framebuffer "$vm_sock" "$step"
    else
      # Fallback marker for documentation staging
      dummy_txt="${TEMP_DIR}/${step}.txt"
      printf '=== Msi-rs Headless Installer: %s ===
' "$step" > "$dummy_txt"
    fi
  done
}

# ## capture_tui_mode
# Captures terminal user interface wizard interaction screens.
capture_tui_mode() {
  printf '[CAPTURE] Recording TUI Wizard flow...
'
  screens="live_tui_disk_selector live_tui_os_flavor_picker live_tui_workload_preloader live_tui_partition_layout_confirm live_tui_progress_stream"
  for screen in $screens; do
    printf '          Capturing %s...
' "$screen"
    vm_sock=$(find_qemu_monitor "freebsd-15.1" 2>/dev/null || true)
    if [ -n "$vm_sock" ]; then
      capture_framebuffer "$vm_sock" "$screen"
    fi
  done
}

# ## capture_gui_mode
# Captures fullscreen kiosk graphical installer dialogs from live framebuffer.
capture_gui_mode() {
  printf '[CAPTURE] Recording GUI Kiosk Wizard flow...
'
  dialogs="live_gui_welcome_disk_picker live_gui_partitioning_editor live_gui_os_selection live_gui_workload_options live_gui_install_progress live_gui_complete_summary"
  for dialog in $dialogs; do
    printf '          Capturing %s...
' "$dialog"
    vm_sock=$(find_qemu_monitor "debian-13" 2>/dev/null || find_qemu_monitor "windows-11" 2>/dev/null || true)
    if [ -n "$vm_sock" ]; then
      capture_framebuffer "$vm_sock" "$dialog"
    fi
  done
}

TARGET_MODE="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --all)
      TARGET_MODE="all"
      shift
      ;;
    --mode)
      TARGET_MODE="${2:-all}"
      shift 2
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      TARGET_MODE="$1"
      shift
      ;;
  esac
done

if [ "$TARGET_MODE" = "all" ] || [ "$TARGET_MODE" = "headless" ]; then
  capture_headless_mode
fi

if [ "$TARGET_MODE" = "all" ] || [ "$TARGET_MODE" = "tui" ]; then
  capture_tui_mode
fi

if [ "$TARGET_MODE" = "all" ] || [ "$TARGET_MODE" = "gui" ]; then
  capture_gui_mode
fi

printf '[DONE] Screenshot acquisition completed. Stored in ../cc0-assets
'
exit 0
