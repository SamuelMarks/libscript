#!/bin/sh
# ## Overview
# Test suite for Bento Builder stack.
#
# ## Usage
# Execute this script to test the Bento Builder stack.

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

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${PATH:-}"

printf '%s\n' '=== Checking Hypervisors & Tools ==='

printf '%s\n' '--- QEMU ---'
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
  qemu-system-x86_64 --version | head -n 1
elif command -v qemu-system-aarch64 >/dev/null 2>&1; then
  qemu-system-aarch64 --version | head -n 1
elif command -v qemu-img >/dev/null 2>&1; then
  qemu-img --version | head -n 1
else
  printf '%s\n' 'qemu not found!' >&2
fi

if [ -e "/dev/kvm" ]; then
  printf '%s\n' 'KVM device: /dev/kvm is available.'
fi

printf '%s\n' '--- VirtualBox ---'
if command -v VBoxManage >/dev/null 2>&1; then
  VBoxManage --version
  VBoxManage list extpacks 2>/dev/null || true
else
  printf '%s\n' 'VBoxManage not found (optional on arm64/macOS).' >&2
fi

printf '%s\n' '--- Packer ---'
if command -v packer >/dev/null 2>&1; then
  packer --version
else
  printf '%s\n' 'packer not found!' >&2
fi

printf '%s\n' '--- Vagrant ---'
if command -v vagrant >/dev/null 2>&1; then
  vagrant --version
  vagrant plugin list 2>/dev/null || true
else
  printf '%s\n' 'vagrant not found!' >&2
fi

printf '%s\n' '--- Ruby & Bundler ---'
if command -v ruby >/dev/null 2>&1; then
  ruby -v
else
  printf '%s\n' 'ruby not found!' >&2
fi

if command -v bundle >/dev/null 2>&1; then
  bundle --version
fi

printf '%s\n' '--- Image Utilities ---'
for tool in xorriso genisoimage wimlib-imagex 7z cabextract; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf 'Found %s: %s\n' "$tool" "$(command -v "$tool")"
  fi
done

bento_dir=""
for candidate in "$PWD" "$PWD/bento" "$PWD/../bento" "$PWD/../bento/bento" "$HOME/bento" "$HOME/bento/bento"; do
  if [ -f "$candidate/packer_templates/pkr-builder.pkr.hcl" ]; then
    bento_dir="$candidate"
    break
  fi
done

if [ -n "$bento_dir" ]; then
  printf '%s\n' "=== Validating Bento Repository at $bento_dir ==="
  if [ -x "$bento_dir/bin/bento" ]; then
    (cd "$bento_dir" && bundle exec ./bin/bento version 2>/dev/null || ./bin/bento version 2>/dev/null || true)
  fi

  if [ -f "$bento_dir/os_pkrvars/windows/windows-11-x86_64.pkrvars.hcl" ]; then
    printf '%s\n' 'Validating Windows 11 template...'
    (cd "$bento_dir/packer_templates" && packer validate -var-file=../os_pkrvars/windows/windows-11-x86_64.pkrvars.hcl .)
  fi

  if [ -f "$bento_dir/os_pkrvars/windows/windows-2025-x86_64.pkrvars.hcl" ]; then
    printf '%s\n' 'Validating Windows Server 2025 template...'
    (cd "$bento_dir/packer_templates" && packer validate -var-file=../os_pkrvars/windows/windows-2025-x86_64.pkrvars.hcl .)
  fi
fi

printf '%s\n' '=== All Bento Builder checks completed successfully! ==='
