#!/bin/sh
# ## Overview
# Tests MSI building across multiple platforms via Vagrant.
#
# ## Usage
#   ./packaging/test_msi_builds.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

cd "${LIBSCRIPT_ROOT_DIR}/vagrant" || exit 1

VMS="windows-11 macos-14-arm64 debian-13 freebsd-15.1 omnios"

for VM in $VMS; do
  printf '[INFO] Testing on %s...\n' "$VM"
  (
    cd "$VM" || exit 1
    vagrant up || exit 1
    
    # Path handling differs on Windows vs Unix VMs
    if [ "$VM" = "windows-11" ]; then
      vagrant ssh -c 'cmd.exe /c "C:\libscript\packaging\build_msi.cmd --out C:\libscript\test_build"' || exit 1
    else
      vagrant ssh -c '/bin/sh /vagrant/packaging/build_msi.sh --out /vagrant/test_build' || exit 1
    fi
    printf '[PASS] %s built successfully.\n' "$VM"
  )
done

printf '[PASS] All platforms tested successfully.\n'
