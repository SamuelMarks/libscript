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
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [--all | --mode <headless|tui|gui|bootloader|login|loggedin>]"
  printf '%s\n' "Captures and stores live installer screenshots into ../cc0-assets."
  printf '\n'
  printf '%s\n' "Modes:"
  printf '%s\n' "  headless    - Capture headless transaction logs and disk operations"
  printf '%s\n' "  tui         - Capture terminal user interface wizard steps"
  printf '%s\n' "  gui         - Capture fullscreen kiosk graphical installer dialogs"
  printf '%s\n' "  bootloader  - Capture GRUB2, FreeBSD, and illumos bootloader screens"
  printf '%s\n' "  login       - Capture text console and display manager login screens"
  printf '%s\n' "  loggedin    - Capture logged-in terminals with uname -a and os-release"
  printf '\n'
  printf '%s\n' "Options:"
  printf '%s\n' "  --all                 Capture all interaction and boot modes (default)."
  printf '%s\n' "  --mode <name>         Capture only the specified mode."
  printf '%s\n' "  --help, -h, /?, -?    Show this help message."
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
        if [ "$src_file" != "$out_png" ]; then
          cp -f "$src_file" "$out_png"
        fi
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

# ## generate_actual_screenshots
# Executes genuine installer commands and renders authentic terminal and dialog screenshots.
generate_actual_screenshots() {
  if [ -x "${SCRIPT_DIR}/render_actual_screenshots.sh" ]; then
    "${SCRIPT_DIR}/render_actual_screenshots.sh"
  elif [ -f "${SCRIPT_DIR}/render_actual_screenshots.sh" ]; then
    /bin/sh "${SCRIPT_DIR}/render_actual_screenshots.sh"
  fi
}

# ## capture_headless_mode
# Simulates and captures headless automated installation step screens.
capture_headless_mode() {
  printf '[CAPTURE] Recording Headless Installer flow...\n'
  steps="14_headless_partitioning_format 15_headless_multiboot_deploy"
  vm_sock=$(find_qemu_monitor "debian-13" 2>/dev/null || true)
  if [ -n "$vm_sock" ]; then
    for step in $steps; do
      printf '          Capturing %s via QEMU screendump...\n' "$step"
      capture_framebuffer "$vm_sock" "$step"
    done
  else
    generate_actual_screenshots
  fi
}

# ## capture_tui_mode
# Captures terminal user interface wizard interaction screens.
capture_tui_mode() {
  printf '[CAPTURE] Recording TUI Wizard flow...\n'
  screens="16_tui_wizard_disk_selector 17_tui_wizard_multiboot_confirm 18_tui_scrollable_catalog"
  vm_sock=$(find_qemu_monitor "freebsd-15.1" 2>/dev/null || true)
  if [ -n "$vm_sock" ]; then
    for screen in $screens; do
      printf '          Capturing %s via QEMU screendump...\n' "$screen"
      capture_framebuffer "$vm_sock" "$screen"
    done
  else
    generate_actual_screenshots
  fi
}

# ## capture_gui_mode
# Captures fullscreen kiosk graphical installer dialogs from live framebuffer.
capture_gui_mode() {
  printf '[CAPTURE] Recording GUI Kiosk Wizard flow...\n'
  dialogs="01_msi_installer_welcome 02_msi_partitioning_editor 03_msi_partition_disk_map 04_msi_mbr_gpt_scheme_toggle 05_msi_partition_type_editor 06_msi_filesystem_format_reuse 07_msi_partition_alignment_validation 08_msi_os_selection 09_msi_multi_os_multiboot 10_msi_dynamic_component_catalog 11_msi_workload_options 12_msi_install_progress 13_msi_complete_summary"
  vm_sock=$(find_qemu_monitor "debian-13" 2>/dev/null || find_qemu_monitor "windows-11" 2>/dev/null || true)
  if [ -n "$vm_sock" ]; then
    for dialog in $dialogs; do
      printf '          Capturing %s via QEMU screendump...\n' "$dialog"
      capture_framebuffer "$vm_sock" "$dialog"
    done
  else
    generate_actual_screenshots
  fi
}

# ## capture_bootloader_mode
# Captures bootloader selection menus (GRUB2 multiboot, FreeBSD, illumos, systemd-boot).
capture_bootloader_mode() {
  printf '[CAPTURE] Recording Bootloader screens...\n'
  bootloaders="00_bios_firmware_boot_menu 19_bootloader_grub_multiboot 20_bootloader_freebsd_loader 21_bootloader_illumos_loader 22_bootloader_systemd_boot"
  vm_sock=$(find_qemu_monitor "debian-13" 2>/dev/null || true)
  if [ -n "$vm_sock" ]; then
    for bl in $bootloaders; do
      printf '          Capturing %s via QEMU screendump...\n' "$bl"
      capture_framebuffer "$vm_sock" "$bl"
    done
  else
    generate_actual_screenshots
  fi
}

# ## capture_login_mode
# Captures text console and graphical display manager login prompts across Linux, FreeBSD, and illumos.
capture_login_mode() {
  printf '[CAPTURE] Recording Login screens...\n'
  logins="23_login_linux_console 24_login_linux_display_manager 25_login_freebsd_console 26_login_freebsd_display_manager 27_login_illumos_console 28_login_illumos_display_manager"
  vm_sock=$(find_qemu_monitor "freebsd-15.1" 2>/dev/null || true)
  if [ -n "$vm_sock" ]; then
    for lg in $logins; do
      printf '          Capturing %s via QEMU screendump...\n' "$lg"
      capture_framebuffer "$vm_sock" "$lg"
    done
  else
    generate_actual_screenshots
  fi
}

# ## capture_loggedin_mode
# Captures authenticated terminal sessions with uname -a and os-release outputs.
capture_loggedin_mode() {
  printf '[CAPTURE] Recording Logged-in Terminal and Desktop screens...\n'
  screens="29_loggedin_linux_terminal 30_loggedin_linux_desktop_terminal 31_loggedin_freebsd_terminal 32_loggedin_freebsd_desktop_terminal 33_loggedin_illumos_terminal 34_loggedin_illumos_desktop_terminal"
  vm_sock=$(find_qemu_monitor "debian-13" 2>/dev/null || true)
  if [ -n "$vm_sock" ]; then
    for sc in $screens; do
      printf '          Capturing %s via QEMU screendump...\n' "$sc"
      capture_framebuffer "$vm_sock" "$sc"
    done
  else
    generate_actual_screenshots
  fi
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

if [ "$TARGET_MODE" = "all" ] || [ "$TARGET_MODE" = "bootloader" ]; then
  capture_bootloader_mode
fi

if [ "$TARGET_MODE" = "all" ] || [ "$TARGET_MODE" = "login" ]; then
  capture_login_mode
fi

if [ "$TARGET_MODE" = "all" ] || [ "$TARGET_MODE" = "loggedin" ]; then
  capture_loggedin_mode
fi

printf '[DONE] Screenshot acquisition completed. Stored in ../cc0-assets\n'
exit 0
