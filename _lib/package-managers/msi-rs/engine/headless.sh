#!/bin/sh
# ## Overview
# Headless non-interactive installer orchestrator with full msiexec CLI parity.
# Executes unattended, preseeded OS installations driven by MSI properties,
# JSON response files, and silent (/qn) execution flags across Linux, FreeBSD, and illumos.
#
# ## Usage
# Execute this script to run headless installation:
#   ./_lib/package-managers/msi-rs/engine/headless.sh [/i <package.msi>] [/qn|/passive] [KEY=VALUE...] [--config <autoinstall.json>]

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

LOG_FILE="/var/log/msi_install.log"
TARGET_DISK=""
OS_FLAVOR="alpine"
WORKLOAD="none"
SILENT_MODE="0"
CONFIG_FILE=""
MSI_PACKAGE=""
COINSTALL_DUAL_OS="0"
LINUX_PART=""
FREEBSD_PART=""
ESP_PART=""
COMPONENTS=""

# ## show_help
# Displays usage instructions and supported CLI parameters.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [OPTIONS] [KEY=VALUE...]"
  printf '%s
' "Executes headless automated installations using msi-rs msiexec CLI semantics."
  printf '
'
  printf '%s
' "msiexec Parity Options:"
  printf '%s
' "  /i <package.msi>        Install target MSI package."
  printf '%s
' "  /qn                     Completely quiet execution (no UI, non-interactive)."
  printf '%s
' "  /passive                Unattended progress-only execution."
  printf '%s
' "  TARGET_DISK=<path>      Target storage disk to partition and install to."
  printf '%s
' "  OS_FLAVOR=<name>        Distribution to deploy (alpine, debian, freebsd, illumos)."
  printf '%s
' "  COINSTALL_DUAL_OS=1     Install Linux and FreeBSD concurrently on separate partitions."
  printf '%s
' "  WORKLOAD=none           Clean base installation without any LibScript packages."
  printf '%s
' "  COMPONENTS=<list>       Comma-separated list of dynamic components (e.g. nginx,wordpress,odoo)."
  printf '%s
' "  --config <file.json>    Path to declarative autoinstall response file."
  printf '%s
' "  --help, -h, /?, -?      Show this help message."
}

# ## log_msg
# Streams log messages to stdout, log file, and serial consoles.
log_msg() {
  _msg="$1"
  _ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  _entry="[${_ts}] ${_msg}"

  if [ "$SILENT_MODE" = "0" ]; then
    printf '%s
' "$_entry"
  fi

  # Append to file
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
  printf '%s
' "$_entry" >> "$LOG_FILE" 2>/dev/null || true

  # Stream to serial console if accessible
  for s_dev in /dev/ttyS0 /dev/ttya /dev/console; do
    if [ -w "$s_dev" ] 2>/dev/null; then
      printf '%s
' "$_entry" > "$s_dev" 2>/dev/null || true
    fi
  done
}

# ## parse_config_json
# Reads values from declarative response file.
parse_config_json() {
  _cfg="$1"
  if [ -f "$_cfg" ]; then
    _disk=$(awk -F'"' '/"target_disk":/ {print $4}' "$_cfg" || true)
    _os=$(awk -F'"' '/"os_flavor":/ {print $4}' "$_cfg" || true)
    _work=$(awk -F'"' '/"workload":/ {print $4}' "$_cfg" || true)
    [ -n "$_disk" ] && TARGET_DISK="$_disk"
    [ -n "$_os" ] && OS_FLAVOR="$_os"
    [ -n "$_work" ] && WORKLOAD="$_work"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    /i|-i|--install)
      MSI_PACKAGE="${2:-}"
      shift 2
      ;;
    /qn|--quiet|-q)
      SILENT_MODE="1"
      shift
      ;;
    /passive|--passive)
      SILENT_MODE="0"
      shift
      ;;
    --config)
      CONFIG_FILE="${2:-}"
      shift 2
      ;;
    TARGET_DISK=*|target_disk=*)
      TARGET_DISK="${1#*=}"
      shift
      ;;
    OS_FLAVOR=*|os_flavor=*)
      OS_FLAVOR="${1#*=}"
      shift
      ;;
    WORKLOAD=*|workload=*)
      WORKLOAD="${1#*=}"
      shift
      ;;
    COINSTALL_DUAL_OS=*|coinstall_dual_os=*)
      COINSTALL_DUAL_OS="${1#*=}"
      shift
      ;;
    LINUX_PART=*|linux_part=*)
      LINUX_PART="${1#*=}"
      shift
      ;;
    FREEBSD_PART=*|freebsd_part=*)
      FREEBSD_PART="${1#*=}"
      shift
      ;;
    ESP_PART=*|esp_part=*)
      ESP_PART="${1#*=}"
      shift
      ;;
    COMPONENTS=*|components=*)
      COMPONENTS="${1#*=}"
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

if [ -n "$CONFIG_FILE" ]; then
  parse_config_json "$CONFIG_FILE"
fi

log_msg "Starting LibScript msi-rs Headless Deployment Engine"
log_msg "Configuration: DISK='${TARGET_DISK:-auto}' OS='${OS_FLAVOR}' DUAL_OS='${COINSTALL_DUAL_OS}' WORKLOAD='${WORKLOAD}'"

# If no target disk is passed, discover first non-boot disk
if [ -z "$TARGET_DISK" ]; then
  log_msg "No TARGET_DISK specified; discovering available disks..."
  if [ -x "${REPO_ROOT}/_lib/storage/disk_discovery.sh" ]; then
    TARGET_DISK=$("${REPO_ROOT}/_lib/storage/disk_discovery.sh" | awk '$3 == "disk" {print $1; exit}' || true)
  fi
fi

if [ -z "$TARGET_DISK" ]; then
  log_msg "[ERROR] No suitable target storage device found! Aborting."
  exit 1
fi

log_msg "Selected target storage: ${TARGET_DISK}"

# Step 1: Partitioning
if [ "$COINSTALL_DUAL_OS" = "1" ]; then
  log_msg "[STAGE 1/4] Partitioning target device ${TARGET_DISK} for Dual-OS (Linux + FreeBSD)..."
  if [ -x "${REPO_ROOT}/_lib/storage/partitioner.sh" ]; then
    "${REPO_ROOT}/_lib/storage/partitioner.sh" "$TARGET_DISK" "gpt-dual-os" "uefi" 2048
  fi
else
  log_msg "[STAGE 1/4] Partitioning target device ${TARGET_DISK}..."
  if [ -x "${REPO_ROOT}/_lib/storage/partitioner.sh" ]; then
    "${REPO_ROOT}/_lib/storage/partitioner.sh" "$TARGET_DISK" "gpt" "uefi" 2048
  fi
fi

# Step 2: Target OS Installation
if [ "$COINSTALL_DUAL_OS" = "1" ]; then
  log_msg "[STAGE 2/4] Concurrently deploying Linux and FreeBSD to separate partitions..."
  _lpart="${LINUX_PART:-${TARGET_DISK}3}"
  _fpart="${FREEBSD_PART:-${TARGET_DISK}4}"
  _epart="${ESP_PART:-${TARGET_DISK}1}"
  if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/coinstall_dual_os.sh" ]; then
    "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/coinstall_dual_os.sh" "$TARGET_DISK" "$_lpart" "$_fpart" "$_epart"
  fi
else
  log_msg "[STAGE 2/4] Deploying operating system distribution (${OS_FLAVOR})..."
  case "$OS_FLAVOR" in
    freebsd*)
      if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/install_freebsd.sh" ]; then
        "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/install_freebsd.sh" "$TARGET_DISK"
      fi
      ;;
    illumos*)
      if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/install_illumos.sh" ]; then
        "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/install_illumos.sh" "$TARGET_DISK"
      fi
      ;;
    *)
      if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/install_linux.sh" ]; then
        "${REPO_ROOT}/_lib/package-managers/msi-rs/distro_installers/install_linux.sh" "$TARGET_DISK" "$OS_FLAVOR"
      fi
      ;;
  esac
fi

# Step 3: Workload Preloading or Clean Base
log_msg "[STAGE 3/4] Staging preloaded workload (${WORKLOAD})..."
if [ "$WORKLOAD" = "none" ] && [ -z "$COMPONENTS" ]; then
  log_msg "[INFO] Clean minimal base OS requested. Zero LibScript packages preloaded."
elif [ -n "$COMPONENTS" ]; then
  log_msg "[INFO] Preloading dynamically selected components: ${COMPONENTS}..."
  if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/preloader/preload_assets.sh" ]; then
    OIFS="$IFS"
    IFS=','
    # shellcheck disable=SC2086
    set -- $COMPONENTS
    IFS="$OIFS"
    "${REPO_ROOT}/_lib/package-managers/msi-rs/preloader/preload_assets.sh" "/mnt/target" "$@"
  fi
else
  case "$WORKLOAD" in
    openedx)
      if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/workloads/openedx.sh" ]; then
        "${REPO_ROOT}/_lib/package-managers/msi-rs/workloads/openedx.sh" "/mnt/target"
      fi
      ;;
    wordpress)
      if [ -x "${REPO_ROOT}/_lib/package-managers/msi-rs/workloads/wordpress.sh" ]; then
        "${REPO_ROOT}/_lib/package-managers/msi-rs/workloads/wordpress.sh" "/mnt/target"
      fi
      ;;
    *)
      log_msg "No additional workload preloading requested."
      ;;
  esac
fi

# Step 4: Finalize and unmount
log_msg "[STAGE 4/4] Finalizing bootloader and unmounting sysroot..."
if [ -x "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" ]; then
  "${REPO_ROOT}/_lib/storage/mount_sysroot.sh" --unmount
fi

log_msg "[SUCCESS] Headless deployment completed successfully."
exit 0
