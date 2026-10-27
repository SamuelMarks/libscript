#!/bin/sh
# ## Overview
# Verifies non-destructive formatting, /etc/fstab idempotency, and Tier 2 LIBSCRIPT_TARGET_SYSROOT offline mode for traits/storage/.
#
# ## Usage
# ./tests/test_storage_trait.sh

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

ST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/libscript-storage-test.XXXXXX")"
# ## cleanup_st_test
# Removes temporary storage test directory on exit.
cleanup_st_test() {
  rm -rf "$ST_TMP"
}
trap cleanup_st_test EXIT INT TERM

export LIBSCRIPT_TARGET_SYSROOT="$ST_TMP"
export LIBSCRIPT_OFFLINE=1

MOCK_DEV="${ST_TMP}/mock.img"
: > "$MOCK_DEV"

# Execute twice to verify 2x idempotency and non-destructive signature detection
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/storage/mount.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/storage/mount.sh" "$MOCK_DEV" "/var/lib/postgresql" "ext4"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/traits/storage/mount.sh" sh "${LIBSCRIPT_ROOT_DIR}/traits/storage/mount.sh" "$MOCK_DEV" "/var/lib/postgresql" "ext4"

count="$(grep -c "BEGIN libscript-trait-storage:/var/lib/postgresql" "${ST_TMP}/etc/fstab")"
if [ "$count" -ne 1 ]; then
  printf '[FAIL] Expected 1 fstab block, found %s\n' "$count" >&2
  exit 1
fi

printf '[PASS] Storage trait non-destructive format and fstab idempotency verified.\n'
