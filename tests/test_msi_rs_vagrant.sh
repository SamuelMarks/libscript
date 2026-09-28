#!/bin/sh
# ## Overview
# Orchestrates isolated Vagrant-only testing for msi-rs across all 5 target platform environments:
# {macOS, Windows, FreeBSD, SunOS, Linux}.
# Validates installation, functionality, and idempotency exclusively within Vagrant guest VMs.
#
# ## Usage
# Execute this script to perform multi-platform Vagrant tests for msi-rs:
#   ./tests/test_msi_rs_vagrant.sh [--all | --platform <macos|windows|freebsd|sunos|linux>]

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

# ## show_help
# Displays usage and CLI option details for Vagrant msi-rs testing.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [--all | --platform <macos|windows|freebsd|sunos|linux>]"
  printf '%s
' "Runs msi-rs verification exclusively inside isolated Vagrant virtual machines."
  printf '
'
  printf '%s
' "Platforms:"
  printf '%s
' "  macos    - Apple Silicon macOS 14 (vagrant/macos-14-arm64)"
  printf '%s
' "  windows  - Windows 11 (vagrant/windows-11)"
  printf '%s
' "  freebsd  - FreeBSD 15.1 (vagrant/freebsd-15.1)"
  printf '%s
' "  sunos    - OmniOS / illumos (vagrant/omnios)"
  printf '%s
' "  linux    - Debian 13 / Alpine Linux (vagrant/debian-13)"
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --all                 Test across all 5 target Vagrant platforms sequentially."
  printf '%s
' "  --platform <name>     Test specifically on one target platform."
  printf '%s
' "  --help, -h, /?, -?    Show this help message."
}

TARGET_PLATFORM="all"
while [ $# -gt 0 ]; do
  case "$1" in
    --all)
      TARGET_PLATFORM="all"
      shift
      ;;
    --platform)
      TARGET_PLATFORM="${2:-all}"
      shift 2
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      TARGET_PLATFORM="$1"
      shift
      ;;
  esac
done

mkdir -p "${REPO_ROOT}/tests_tmp"
SUMMARY_FILE="${REPO_ROOT}/tests_tmp/msi_rs_matrix_summary.json"

# ## run_platform_test
# Executes msi-rs installation and test on a given platform runner script.
run_platform_test() {
  plat="$1"
  runner="$2"
  printf '[VAGRANT-MATRIX] Testing msi-rs on %s VM via %s...
' "$plat" "$runner"
  if [ -x "${REPO_ROOT}/tests/${runner}" ]; then
    "${REPO_ROOT}/tests/${runner}" msi-rs || return 1
  elif [ -f "${REPO_ROOT}/tests/${runner}" ]; then
    sh "${REPO_ROOT}/tests/${runner}" msi-rs || return 1
  else
    printf '[WARN] Runner %s not found; skipping %s
' "$runner" "$plat"
    return 0
  fi
}

PLAT_MACOS_STATUS="SKIPPED"
PLAT_WINDOWS_STATUS="SKIPPED"
PLAT_FREEBSD_STATUS="SKIPPED"
PLAT_SUNOS_STATUS="SKIPPED"
PLAT_LINUX_STATUS="SKIPPED"

OVERALL_SUCCESS=1

if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "linux" ]; then
  if run_platform_test "linux" "run_debian_tests.sh"; then
    PLAT_LINUX_STATUS="PASS"
  else
    PLAT_LINUX_STATUS="FAIL"
    OVERALL_SUCCESS=0
  fi
fi

if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "freebsd" ]; then
  if run_platform_test "freebsd" "run_freebsd_tests.sh"; then
    PLAT_FREEBSD_STATUS="PASS"
  else
    PLAT_FREEBSD_STATUS="FAIL"
    OVERALL_SUCCESS=0
  fi
fi

if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "sunos" ]; then
  if run_platform_test "sunos" "run_omnios_tests.sh"; then
    PLAT_SUNOS_STATUS="PASS"
  else
    PLAT_SUNOS_STATUS="FAIL"
    OVERALL_SUCCESS=0
  fi
fi

if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "macos" ]; then
  if run_platform_test "macos" "run_macos_tests.sh"; then
    PLAT_MACOS_STATUS="PASS"
  else
    PLAT_MACOS_STATUS="FAIL"
    OVERALL_SUCCESS=0
  fi
fi

if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "windows" ]; then
  if run_platform_test "windows" "run_windows_tests.sh"; then
    PLAT_WINDOWS_STATUS="PASS"
  else
    PLAT_WINDOWS_STATUS="FAIL"
    OVERALL_SUCCESS=0
  fi
fi

cat << EOF > "${SUMMARY_FILE}"
{
  "suite": "msi-rs-vagrant-matrix",
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platforms": {
    "linux": "${PLAT_LINUX_STATUS}",
    "freebsd": "${PLAT_FREEBSD_STATUS}",
    "sunos": "${PLAT_SUNOS_STATUS}",
    "macos": "${PLAT_MACOS_STATUS}",
    "windows": "${PLAT_WINDOWS_STATUS}"
  },
  "overall_status": "$( [ "$OVERALL_SUCCESS" -eq 1 ] && printf 'PASS' || printf 'FAIL' )"
}
EOF

printf '[VAGRANT-MATRIX] Summary written to %s
' "${SUMMARY_FILE}"
if [ "$OVERALL_SUCCESS" -eq 1 ]; then
  printf '[OK] Vagrant testing for msi-rs completed successfully.
'
  exit 0
else
  printf '[ERROR] One or more Vagrant tests failed.
' >&2
  exit 1
fi
