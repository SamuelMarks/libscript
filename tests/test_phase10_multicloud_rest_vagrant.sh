#!/bin/sh
# ## Overview
# Phase 10 integration & 2x-idempotency suite verifying multicloud `image-import` distro registration,
# `/v1/package-as` OpenAPI 3.2.0 + C11 REST API endpoints, and cross-OS Vagrant `package-as` matrix jobs.
# ## Usage
# ./tests/test_phase10_multicloud_rest_vagrant.sh
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

TMP_P10=$(mktemp -d "${TMPDIR:-/tmp}/libscript_phase10.XXXXXX")

# ## cleanup_phase10
# Removes temporary build artifacts created during Phase 10 verification.
cleanup_phase10() {
  rm -rf "$TMP_P10"
}
trap 'cleanup_phase10' EXIT INT TERM

# 1. Multicloud distro artifact import (AWS AMI, GCP Compute Image, Azure Managed Image) + 2x idempotency
STACK='' "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/image-import/test.sh"

# 2. Native C11 /v1/package-as OpenAPI 3.2.0 endpoints + CLI/CTest/HTTP polling
STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/test_rest_api.sh"

# 3. Cross-OS Vagrant CI matrix (Windows 11, Windows Server 2025, Linux, FreeBSD, macOS, OmniOS) + 2x idempotency
LIBSCRIPT_BUILD_DIR="${TMP_P10}/build" STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/test_package_as_vagrant_matrix.sh"
_out2=$(LIBSCRIPT_BUILD_DIR="${TMP_P10}/build" STACK='' "${LIBSCRIPT_ROOT_DIR}/tests/test_package_as_vagrant_matrix.sh")
case "$_out2" in
  *'[SKIP]'*) ;;
  *)
    printf '[FAIL] Expected [SKIP] on 2nd Vagrant matrix run\n' >&2
    exit 1
    ;;
esac

cleanup_phase10
printf '[PASS] All Phase 10 multicloud image-import, /v1/package-as REST API, and Vagrant matrix tests passed.\n'
exit 0
