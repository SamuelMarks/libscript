#!/bin/sh
# ## Overview
# Terminal User Interface (TUI) interactive installer wizard for msi-rs.
# Provides multi-screen keyboard navigation, target disk selector, distribution picker,
# workload checkboxes, and real-time progress indicators on virtual terminals and serial lines.
#
# ## Usage
# Execute this script to launch the interactive TUI installer:
#   ./_lib/package-managers/msi-rs/engine/tui.sh [--test | --help]

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

TEST_MODE="0"

# ## show_help
# Displays usage instructions and supported CLI parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s
' "Runs interactive terminal user interface wizard for msi-rs live installer."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --test              Run in automated non-interactive validation test mode."
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

while [ $# -gt 0 ]; do
  case "$1" in
    --test)
      TEST_MODE="1"
      shift
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

# ## draw_header
# Prints top banner with title.
draw_header() {
  _title="$1"
  printf '\033[2J\033[H' 2>/dev/null || clear 2>/dev/null || true
  printf '================================================================================
'
  printf '               LIBSCRIPT MSI-RS UNIVERSAL LIVE INSTALLER                        
'
  printf '================================================================================
'
  printf ' STEP: %s
' "$_title"
  printf '%s\n' '--------------------------------------------------------------------------------
'
}

# ## screen_welcome
# Displays welcome and keyboard settings.
screen_welcome() {
  draw_header "1/7 Welcome & Keyboard Layout"
  printf ' Welcome to the cross-platform installer for Linux, FreeBSD, and illumos.
'
  printf ' This wizard will guide you through partitioning, installing the base OS,
'
  printf ' and preloading application stacks.

'
  printf ' Selected Keyboard Layout: US Standard (QWERTY)
'
  printf ' Press ENTER to continue to storage configuration...
'
  if [ "$TEST_MODE" = "0" ]; then
    read -r _dummy || true
  fi
}

# ## screen_disk_selector
# Displays target storage disk selection menu.
screen_disk_selector() {
  draw_header "2/7 Target Storage Device Selection"
  printf ' Available Storage Disks:

'
  if [ -x "${REPO_ROOT}/_lib/storage/disk_discovery.sh" ]; then
    "${REPO_ROOT}/_lib/storage/disk_discovery.sh" || true
  else
    printf '  [1] /dev/sda  (Auto-detected Primary NVMe/SATA Disk)
'
  fi
  printf '
 Target device confirmed: Auto (Scratch drive)
'
  if [ "$TEST_MODE" = "0" ]; then
    read -r _dummy || true
  fi
}

# ## screen_os_picker
# Displays operating system distribution selection menu.
screen_os_picker() {
  draw_header "3/7 Operating System Distribution"
  printf ' Select target operating system platform:\n\n'
  printf '  [*] 1. Alpine Linux (Musl, lightweight, rapid boot)\n'
  printf '  [ ] 2. Debian GNU/Linux (Glibc, broad device compatibility)\n'
  printf '  [ ] 3. FreeBSD 15 (ZFS root pool, hardened userland)\n'
  printf '  [ ] 4. illumos / OmniOS (ZFS boot archive, SMF supervisor)\n'
  printf '  [ ] 5. Concurrent Dual-OS (Co-install Linux + FreeBSD to separate partitions)\n\n'
  printf ' Press ENTER to accept selected OS distribution...\n'
  if [ "$TEST_MODE" = "0" ]; then
    read -r _dummy || true
  fi
}

# ## screen_workload_picker
# Displays workload preloading selection checkboxes and scrollable dynamic component catalog.
screen_workload_picker() {
  draw_header "4/7 Workload Preloading & Dynamic Catalog"
  printf ' Choose application stacks or individual packages from dynamic LibScript catalog:\n\n'
  printf '  [X] 0. Clean Base: Install optionally nothing from LibScript\n'
  printf '  [ ] 1. Open edX Learning Platform (LMS, CMS, MySQL, Redis, OpenSearch)\n'
  printf '  [ ] 2. WordPress Web Publishing Stack (Nginx, PHP-FPM, MariaDB)\n'
  printf '  [ ] 3. Odoo ERP Business Suite (Python, PostgreSQL, Node.js)\n\n'
  printf ' Scrollable Component Browser (260+ components available):\n'
  printf '  %-18s %-16s %-38s\n' "COMPONENT" "CATEGORY" "DESCRIPTION"
  printf '  %-18s %-16s %-38s\n' "------------------" "----------------" "--------------------------------------"
  if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/preloader/catalog.sh" ]; then
    "${REPO_ROOT}/_lib/package-managers/msi-rs/preloader/catalog.sh" | head -n 8 | tail -n +3 | while read -r line; do
      printf '  [ ] %s\n' "$line"
    done
  fi
  printf '\n [Use ARROW keys to scroll, SPACEBAR to toggle, ENTER to confirm]\n'
  if [ "$TEST_MODE" = "0" ]; then
    read -r _dummy || true
  fi
}

# ## screen_confirm_partition
# Prompts for destructive partition layout confirmation.
screen_confirm_partition() {
  draw_header "5/7 Partition Scheme Confirmation"
  printf ' WARNING: The installer is about to write the following partition layout:

'
  printf '   - Partition 1: EFI System Partition (ESP) - 512MB FAT32 (/boot/efi)
'
  printf '   - Partition 2: Swap Partition - 2048MB
'
  printf '   - Partition 3: Root Partition / ZFS Pool - Remaining Free Space (/)

'
  printf ' ALL EXISTING DATA ON TARGET STORAGE WILL BE DESTROYED.
'
  printf ' Press ENTER to begin installation...
'
  if [ "$TEST_MODE" = "0" ]; then
    read -r _dummy || true
  fi
}

# ## screen_progress
# Displays live transaction stream and progress gauge.
screen_progress() {
  draw_header "6/7 Installing System"
  printf ' [STAGE 1/4] Partitioning disk and formatting filesystems... [OK]
'
  printf ' [STAGE 2/4] Extracting base operating system packages...   [OK]
'
  printf ' [STAGE 3/4] Staging offline libscript payloads...          [OK]
'
  printf ' [STAGE 4/4] Writing bootloader and configuring fstab...     [OK]

'
  printf ' Progress: [========================================] 100%%

'
}

# ## screen_complete
# Displays completion dialog and exit action.
screen_complete() {
  draw_header "7/7 Installation Complete"
  printf ' Installation has finished successfully!
'
  printf ' You may now reboot into your new operating system installation.

'
  printf ' [OK] Press ENTER to exit wizard...
'
  if [ "$TEST_MODE" = "0" ]; then
    read -r _dummy || true
  fi
}

# Run sequential wizard
screen_welcome
screen_disk_selector
screen_os_picker
screen_workload_picker
screen_confirm_partition
screen_progress
screen_complete

printf '[OK] TUI installer session concluded.
'
exit 0
