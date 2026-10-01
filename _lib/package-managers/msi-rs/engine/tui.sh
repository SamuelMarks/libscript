#!/bin/sh
# ## Overview
# Terminal User Interface (TUI) interactive installer wizard for msi-rs.
# Provides multi-screen keyboard navigation, target disk selector, distribution picker,
# workload checkboxes, and real-time progress indicators using whiptail or dialog.
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


TEST_MODE="0"

# ## show_help
# Displays usage instructions and supported CLI parameters.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [OPTIONS]"
  printf '%s\n' "Runs interactive terminal user interface wizard for msi-rs live installer."
  printf '\n'
  printf '%s\n' "Options:"
  printf '%s\n' "  --test              Run in automated non-interactive validation test mode."
  printf '%s\n' "  --help, -h, /?, -?  Show this help message."
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

if command -v whiptail >/dev/null 2>&1; then
  DIALOG_PROG="whiptail"
elif command -v dialog >/dev/null 2>&1; then
  DIALOG_PROG="dialog"
else
  printf "[ERROR] Neither 'whiptail' nor 'dialog' found. TUI mode requires one of these tools.\n" >&2
  exit 1
fi

if [ "$TEST_MODE" = "1" ]; then
  printf "Running in TEST_MODE. Simulating TUI choices...\n"
  TARGET_DISK="/dev/sda"
  OS_FLAVOR="alpine"
  WORKLOAD="none"
else
  $DIALOG_PROG --title "LibScript msi-rs Universal Live Installer" --msgbox "Welcome to the cross-platform installer for Linux, FreeBSD, and illumos.\n\nThis wizard will guide you through partitioning, installing the base OS, and preloading application stacks." 10 60

  TARGET_DISK=$($DIALOG_PROG --title "Target Storage Selection" --inputbox "Enter the target disk device path (e.g., /dev/sda, /dev/nvme0n1, /dev/da0):" 10 60 "/dev/sda" 3>&1 1>&2 2>&3)
  
  OS_FLAVOR=$($DIALOG_PROG --title "Operating System Selection" --radiolist "Select target operating system platform:" 15 60 4 \
    "alpine" "Alpine Linux (Musl)" ON \
    "debian" "Debian GNU/Linux (Glibc)" OFF \
    "freebsd" "FreeBSD 15 (ZFS root)" OFF \
    "illumos" "illumos / OmniOS (ZFS root)" OFF 3>&1 1>&2 2>&3)
    
  WORKLOAD=$($DIALOG_PROG --title "Workload Selection" --radiolist "Choose application stack to preload:" 15 60 3 \
    "none" "Clean Base OS" ON \
    "openedx" "Open edX Learning Platform" OFF \
    "wordpress" "WordPress Web Publishing" OFF 3>&1 1>&2 2>&3)

  if ! $DIALOG_PROG --title "Partition Confirmation" --yesno "WARNING: The installer will DESTROY ALL EXISTING DATA on ${TARGET_DISK}.\n\nAre you sure you want to proceed with the installation of ${OS_FLAVOR}?" 10 60; then
     printf "Installation aborted by user.\n"
     exit 0
  fi
fi

printf "\n[TUI] Collected Parameters: DISK='%s', OS='%s', WORKLOAD='%s'\n" "$TARGET_DISK" "$OS_FLAVOR" "$WORKLOAD"
printf "[TUI] Passing control to headless engine...\n"

HEADLESS_SCRIPT="${SCRIPT_DIR}/headless.sh"
if [ ! -x "$HEADLESS_SCRIPT" ]; then
   chmod +x "$HEADLESS_SCRIPT"
fi

"$HEADLESS_SCRIPT" "TARGET_DISK=${TARGET_DISK}" "OS_FLAVOR=${OS_FLAVOR}" "WORKLOAD=${WORKLOAD}"

if [ "$TEST_MODE" = "0" ]; then
  $DIALOG_PROG --title "Installation Complete" --msgbox "Installation has finished successfully!\n\nYou may now reboot your system." 10 60
fi

exit 0
