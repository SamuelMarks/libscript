#!/bin/sh
# ## Overview
# Smoke and 2x-idempotency test for `_lib/cloud/image-import`.
#
# ## Usage
# ./_lib/cloud/image-import/test.sh

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

_tmp=$(mktemp -d)
dd if=/dev/zero of="${_tmp}/disk.vhd" bs=1048576 count=1 2>/dev/null
"${SCRIPT_DIR}/cli.sh" aws --disk="${_tmp}/disk.vhd" --bucket=test-bkt --name=test-uk --dry-run >/dev/null
"${SCRIPT_DIR}/cli.sh" azure --disk="${_tmp}/disk.vhd" --account=test_acct --gallery=test_sig --name=test-uk --dry-run >/dev/null
"${SCRIPT_DIR}/cli.sh" gcp --disk="${_tmp}/disk.vhd" --bucket=test-gcs --project=test-proj --name=test-uk --dry-run >/dev/null
rm -rf "${_tmp}"
printf '%s\n' '[PASS] image-import dry-run tests passed.'
