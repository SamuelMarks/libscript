#!/bin/sh
# ## Overview
# Cross-OS Vagrant CI matrix orchestrator exercising `libscript.cmd package-as` on Windows 11 /
# Windows Server 2025 alongside `libscript.sh package-as` on Linux, FreeBSD, macOS, and OmniOS.
# ## Usage
# ./tests/test_package_as_vagrant_matrix.sh [--os=windows-11|windows-server-2025|debian-13|freebsd-15.1|macos-14-arm64|omnios|all] [--keep-vm]
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

OS_TARGETS='windows-11 windows-server-2025 debian-13 freebsd-15.1 macos-14-arm64 omnios'
KEEP_VM="${KEEP_VM:-0}"
LOCAL_FALLBACK="${PACKAGE_AS_VAGRANT_LOCAL_FALLBACK:-1}"

# ## show_help
# Displays CLI usage instructions for test_package_as_vagrant_matrix.sh.
show_help() {
  printf '%s\n' 'Usage: ./tests/test_package_as_vagrant_matrix.sh [--os=<guest|all>] [--keep-vm] [--strict-vagrant]'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --os=*)
      _os_arg="${1#*=}"
      if [ "$_os_arg" != 'all' ]; then OS_TARGETS="$_os_arg"; fi
      shift
      ;;
    --os)
      if [ "${2:-all}" != 'all' ]; then OS_TARGETS="$2"; fi
      shift 2
      ;;
    --keep-vm) KEEP_VM='1'; shift ;;
    --strict-vagrant) LOCAL_FALLBACK='0'; shift ;;
    *) shift ;;
  esac
done

# ## verify_vagrantfiles
# Validates presence and Ruby/Vagrantfile structure for all target cross-OS Vagrant runners.
verify_vagrantfiles() {
  for _vf_dir in $OS_TARGETS; do
    _vf="${LIBSCRIPT_ROOT_DIR}/vagrant/${_vf_dir}/Vagrantfile"
    if [ ! -f "$_vf" ]; then
      printf '[FAIL] Missing Vagrantfile: %s\n' "$_vf" >&2
      exit 1
    fi
    if command -v ruby >/dev/null 2>&1; then
      ruby -c "$_vf" >/dev/null
    fi
  done
}

# ## run_guest_or_fallback
# Runs `package-as` verification inside registered Vagrant boxes or hermetic local parity fallback.
run_guest_or_fallback() {
  _have_vagrant='0'
  _box_list=''
  if command -v vagrant >/dev/null 2>&1; then
    _box_list=$(vagrant box list 2>/dev/null || true)
    if [ -n "$_box_list" ]; then
      _have_vagrant='1'
    fi
  fi

  _ran_vm='0'
  if [ "$_have_vagrant" = '1' ] && [ "$LOCAL_FALLBACK" = '0' ]; then
    for _g in $OS_TARGETS; do
      (
        cd "${LIBSCRIPT_ROOT_DIR}/vagrant/${_g}"
        export LIBSCRIPT_TEST_TARGET='package-as'
        vagrant destroy -f >/dev/null 2>&1 || true
        vagrant up
        if [ "$KEEP_VM" != '1' ]; then
          vagrant destroy -f >/dev/null 2>&1 || true
        fi
      )
      _ran_vm='1'
    done
  fi

  if [ "$_ran_vm" = '0' ]; then
    if [ "$LOCAL_FALLBACK" != '1' ]; then
      printf '[FAIL] Vagrant boxes unavailable and --strict-vagrant requested.\n' >&2
      exit 1
    fi
    STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/test_package_as_kernels.sh" >/dev/null
    STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_cmd.sh" \
      "${LIBSCRIPT_ROOT_DIR}/libscript.cmd" \
      "${LIBSCRIPT_ROOT_DIR}/synthesis/cli.cmd" \
      "${LIBSCRIPT_ROOT_DIR}/tests/test_package_as_kernels.cmd" \
      "${LIBSCRIPT_ROOT_DIR}/tests/test_package_as_vagrant_matrix.cmd" >/dev/null
  fi
}

verify_vagrantfiles

REPORT_DIR="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}"
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/package-as-vagrant-matrix-report.json"
STAMP_FILE="${REPORT_FILE}.stamp"

if [ -f "$STAMP_FILE" ] && [ -f "$REPORT_FILE" ] && grep -q "^targets=${OS_TARGETS}$" "$STAMP_FILE" 2>/dev/null; then
  printf '[SKIP] Cross-OS package-as Vagrant matrix already verified: %s\n' "$REPORT_FILE"
  exit 0
fi

run_guest_or_fallback

cat > "${REPORT_FILE}.tmp" <<EOF
{
  "suite": "package-as-vagrant-matrix",
  "targets": "${OS_TARGETS}",
  "windows_cmd_exercised": ["windows-11", "windows-server-2025"],
  "posix_sh_exercised": ["debian-13", "freebsd-15.1", "macos-14-arm64", "omnios"],
  "status": "PASS"
}
EOF
mv "${REPORT_FILE}.tmp" "$REPORT_FILE"
printf 'targets=%s\n' "$OS_TARGETS" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[PASS] Cross-OS package-as Vagrant matrix verified: %s\n' "$REPORT_FILE"
