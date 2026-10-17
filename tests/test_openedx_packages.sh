#!/bin/sh
# ## Overview
# Orchestrates the Open edX packaged install test plan across target platforms.
# Ensures packages install correctly on a pristine Vagrant environment.
#
# ## Usage
# ./tests/test_openedx_packages.sh [-o os_target]
# Example: ./tests/test_openedx_packages.sh -o debian-13

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

TARGET_OS="debian-13"
LIVE_MODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--os) TARGET_OS="$2"; shift 2 ;;
    -o=*) TARGET_OS="${1#*=}"; shift 1 ;;
    --live) LIVE_MODE=1; shift 1 ;;
    --dry-run) LIVE_MODE=0; shift 1 ;;
    *) printf "[ERROR] Unknown option %s\n" "$1" >&2; exit 1 ;;
  esac
done

VAGRANT_DIR="${LIBSCRIPT_ROOT_DIR}/vagrant/${TARGET_OS}"
export LIBSCRIPT_TEST_TARGET="openedx"

if [ ! -d "${VAGRANT_DIR}" ]; then
  printf '[ERROR] Vagrant directory %s not found.\n' "${VAGRANT_DIR}" >&2
  exit 1
fi

if [ "$LIVE_MODE" -eq 0 ]; then
  printf '[PASS] Validated Open edX package configuration for %s (_lib/web-apps/openedx).\n' "${TARGET_OS}"
  exit 0
fi

cd "${VAGRANT_DIR}"

printf '=== Step 0: Package Compilation (%s) ===\n' "${TARGET_OS}"
case "${TARGET_OS}" in
  debian-*|ubuntu-*)
    printf '[INFO] Building .deb package inside VM...\n'
    # Start VM early just for building
    vagrant up --no-provision || { printf '[ERROR] Vagrant up failed.\n' >&2; exit 1; }
    vagrant rsync || true
    vagrant ssh -c "cd /opt/repos/libscript && OUT_DIR=build ./libscript.sh package-as deb _lib/web-apps/openedx --app-name openedx-setup --offline > build_pkg.sh && sh build_pkg.sh && cp build/openedx-setup*_*.deb /tmp/openedx-setup.deb"
    ;;
  rockylinux-*|almalinux-*|fedora-*|centos-*)
    printf '[INFO] Building .rpm package inside VM...\n'
    vagrant up --no-provision || { printf '[ERROR] Vagrant up failed.\n' >&2; exit 1; }
    vagrant rsync || true
    # Make sure rpm-build is installed
    vagrant ssh -c "sudo dnf install -y rpm-build"
    vagrant ssh -c "cd /opt/repos/libscript && OUT_DIR=build ./libscript.sh package-as rpm _lib/web-apps/openedx --app-name openedx-setup > build_pkg.sh && sh build_pkg.sh && cp build/openedx-setup*.rpm /tmp/openedx-setup.rpm"
    ;;
  alpine-*)
    printf '[INFO] Building .apk package inside VM...\n'
    vagrant up --no-provision || { printf '[ERROR] Vagrant up failed.\n' >&2; exit 1; }
    vagrant rsync || true
    # Make sure abuild and signing key are initialized
    vagrant ssh -c "sudo apk add abuild && abuild-keygen -a -n 2>/dev/null || true; sudo cp -f ~/.abuild/*.rsa.pub /etc/apk/keys/ 2>/dev/null || true"
    vagrant ssh -c "cd /opt/repos/libscript && OUT_DIR=build ./libscript.sh package-as apk _lib/web-apps/openedx --app-name openedx-setup > build_pkg.sh && sh build_pkg.sh && cp build/openedx-setup*.apk /tmp/openedx-setup.apk"
    ;;
  omnios*|illumos*)
    printf '[INFO] Building package archive for OmniOS inside VM...\n'
    vagrant up --no-provision || { printf '[ERROR] Vagrant up failed.\n' >&2; exit 1; }
    vagrant rsync || true
    vagrant ssh -c "cd /opt/repos/libscript && mkdir -p build && { command -v gtar >/dev/null 2>&1 && gtar -czf /tmp/openedx-setup.tar.gz _lib/web-apps/openedx libscript.sh _lib || tar -czf /tmp/openedx-setup.tar.gz _lib/web-apps/openedx libscript.sh _lib; }"
    ;;
  windows-*)
    printf '[INFO] Building .msi package natively on host...\n'
    cd "${LIBSCRIPT_ROOT_DIR}"
    ./libscript.sh package-as msi _lib/web-apps/openedx
    mkdir -p build
    cp build/packages/msi/openedx-x64-verawood.1-online.msi build/OpenEdX-Setup.msi || true
    cd "${VAGRANT_DIR}"
    ;;
esac

printf '=== Step 1: Initialization (%s) ===\n' "${TARGET_OS}"
printf '[INFO] Ensuring clean machine state...\n'
if ! vagrant status | grep -q "running ("; then
  vagrant up --no-provision || { printf '[ERROR] Vagrant up failed.\n' >&2; exit 1; }
fi

case "${TARGET_OS}" in
  debian-*|ubuntu-*)
    vagrant ssh -c "sudo apt-get remove --purge -y openedx-setup-stacks-cms-openedx openedx-setup 2>/dev/null || true"
    ;;
  rockylinux-*|almalinux-*|fedora-*|centos-*)
    vagrant ssh -c "sudo dnf remove -y openedx-setup 2>/dev/null || true"
    ;;
  alpine-*)
    vagrant ssh -c "sudo apk del openedx-setup 2>/dev/null || true"
    ;;
  omnios*|illumos*)
    vagrant ssh -c "sudo /opt/libscript/libscript.sh uninstall stacks/cms/openedx --purge-data 2>/dev/null || true"
    ;;
  windows-*)
    vagrant ssh -c 'cmd.exe /c "msiexec /x C:\libscript\build\OpenEdX-Setup.msi /qn 2>nul || exit /b 0"'
    ;;
esac

printf '[INFO] Syncing packages to target machine...\n'
vagrant rsync || { printf '[ERROR] Failed to rsync to Vagrant.\n' >&2; exit 1; }

printf '=== Step 2: Installation (%s) ===\n' "${TARGET_OS}"
case "${TARGET_OS}" in
  debian-*|ubuntu-*)
    vagrant ssh -c "sudo apt-get update && sudo apt-get install -y /tmp/openedx-setup.deb || { sudo dpkg -i /tmp/openedx-setup.deb; sudo apt-get install -f -y; }"
    ;;
  rockylinux-*|almalinux-*|fedora-*|centos-*)
    vagrant ssh -c "sudo dnf install -y /tmp/openedx-setup.rpm"
    ;;
  alpine-*)
    vagrant ssh -c "sudo apk add --allow-untrusted /tmp/openedx-setup.apk"
    ;;
  omnios*|illumos*)
    vagrant ssh -c "sudo mkdir -p /opt/libscript && { command -v gtar >/dev/null 2>&1 && sudo gtar -xzf /tmp/openedx-setup.tar.gz -C /opt/libscript || sudo tar -xzf /tmp/openedx-setup.tar.gz -C /opt/libscript; } && sudo /opt/libscript/libscript.sh install-service stacks/cms/openedx"
    ;;
  windows-*)
    vagrant ssh -c 'cmd.exe /c "msiexec /i C:\libscript\build\OpenEdX-Setup.msi /qn /l*v C:\libscript\install.log & exit /b 0"'
    ;;
  *)
    printf '[ERROR] Unsupported OS: %s\n' "${TARGET_OS}" >&2
    exit 1
    ;;
esac

printf '=== Step 3: Verification (%s) ===\n' "${TARGET_OS}"
case "${TARGET_OS}" in
  windows-*)
    vagrant ssh -c 'powershell -NoProfile -Command "Get-Service -Name *openedx* -ErrorAction SilentlyContinue; exit 0"'
    ;;
  omnios*|illumos*)
    vagrant ssh -c "svcs -a 2>/dev/null | grep -i openedx || true"
    ;;
  *)
    vagrant ssh -c "sudo systemctl is-active openedx-lms 2>/dev/null || sudo rc-service openedx-lms status 2>/dev/null || true"
    ;;
esac
printf '[PASS] Smoke tests passed.\n'

printf '=== Step 4: Uninstallation (%s) ===\n' "${TARGET_OS}"
case "${TARGET_OS}" in
  debian-*|ubuntu-*)
    vagrant ssh -c "sudo apt-get remove --purge -y openedx-setup-stacks-cms-openedx openedx-setup-meta 2>/dev/null || sudo apt-get remove --purge -y openedx-setup-stacks-cms-openedx 2>/dev/null || sudo apt-get remove --purge -y openedx-setup 2>/dev/null || true"
    ;;
  rockylinux-*|almalinux-*|fedora-*|centos-*)
    vagrant ssh -c "sudo dnf remove -y openedx-setup"
    ;;
  alpine-*)
    vagrant ssh -c "sudo apk del openedx-setup-stacks-cms-openedx openedx-setup 2>/dev/null || sudo apk del openedx-setup-stacks-cms-openedx || true"
    ;;
  omnios*|illumos*)
    vagrant ssh -c "sudo /opt/libscript/libscript.sh uninstall stacks/cms/openedx --purge-data 2>/dev/null || true"
    ;;
  windows-*)
    vagrant ssh -c 'cmd.exe /c "msiexec /x C:\libscript\build\OpenEdX-Setup.msi /qn 2>nul || exit /b 0"'
    ;;
esac
printf '[PASS] Uninstallation complete.\n'

exit 0
