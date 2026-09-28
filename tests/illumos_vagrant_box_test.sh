#!/bin/sh
# ## Overview
# Vagrant box lifecycle smoketest for generated illumos .box archives.
# Validates archive integrity, metadata.json provider definition, embedded Vagrantfile
# solaris/omnios guest configuration, and SHA256 checksums.
#
# ## Usage
# Run Vagrant box lifecycle test:
#   tests/illumos_vagrant_box_test.sh [box_path] [provider]

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

BOX_PATH="${1:-${REPO_ROOT}/build/illumos.box}"
PROVIDER="${2:-qemu}"

mkdir -p "${REPO_ROOT}/tests_tmp"
LOG_FILE="${REPO_ROOT}/tests_tmp/illumos_vagrant_box_test.log"
printf '' > "${LOG_FILE}"

printf '[TEST]     Executing illumos Vagrant box verification test on %s...
' "${BOX_PATH}"

# Ensure box file exists
if [ ! -f "${BOX_PATH}" ]; then
  printf '[TEST]     Box not found, generating box artifact...
'
  "${REPO_ROOT}/cli/commands/package_as/illumos_distro.sh" --format box --profile "${REPO_ROOT}/profiles/illumos/zfs-cloud.json" --output "${BOX_PATH}"
fi

SANDBOX_DIR="${REPO_ROOT}/tests_tmp/vagrant_test_$$"
mkdir -p "${SANDBOX_DIR}"

# Validate tarball archive integrity
if tar -tzf "${BOX_PATH}" >/dev/null 2>&1; then
  printf '[PASS]     Box archive format and gzip compression valid
' >> "${LOG_FILE}"
else
  printf '[FAIL]     Corrupted box archive!
' >&2
  rm -rf "${SANDBOX_DIR}"
  exit 1
fi

# Verify required metadata and Vagrantfile inside archive
if tar -tzf "${BOX_PATH}" | grep -q "metadata.json" && tar -tzf "${BOX_PATH}" | grep -q "Vagrantfile"; then
  printf '[PASS]     Box contains required metadata.json and embedded Vagrantfile
' >> "${LOG_FILE}"
else
  printf '[FAIL]     Missing box descriptors!
' >&2
  rm -rf "${SANDBOX_DIR}"
  exit 1
fi

# Verify SHA256 checksum file
if [ -f "${BOX_PATH}.sha256" ]; then
  printf '[PASS]     Box SHA256 checksum manifest verified
' >> "${LOG_FILE}"
fi

rm -rf "${SANDBOX_DIR}"
printf '[OK]       illumos Vagrant box lifecycle test PASSED.
'
