#!/bin/sh
# ## Overview
# Smoke and 2x-idempotency test for `infrastructure/resources/image-import` across direct disk
# artifacts and `package-as {linux,freebsd,illumos,reactos,unikernel}-distro` outputs.
#
# ## Usage
# ./infrastructure/resources/image-import/test.sh

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
export LIBSCRIPT_BUILD_DIR="${_tmp}/build"
export LIBSCRIPT_OFFLINE='1'
export LIBSCRIPT_ALLOW_STUB='1'

# ## cleanup_tmp
# Removes temporary test directory on exit.
cleanup_tmp() {
  rm -rf "${_tmp}"
}
trap cleanup_tmp EXIT INT TERM

dd if=/dev/zero of="${_tmp}/disk.vhd" bs=1048576 count=1 2>/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" aws --disk="${_tmp}/disk.vhd" --bucket=test-bkt --name=test-uk --dry-run >/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" azure --disk="${_tmp}/disk.vhd" --account=test_acct --gallery=test_sig --name=test-uk --dry-run >/dev/null
STACK='' "${SCRIPT_DIR}/cli.sh" gcp --disk="${_tmp}/disk.vhd" --bucket=test-gcs --project=test-proj --name=test-uk --dry-run >/dev/null

for _spec in \
  'linux-distro:linux-minimal-headless-musl:raw:linux' \
  'freebsd-distro:minimal-server:raw:freebsd' \
  'illumos-distro:minimal-server:raw:illumos' \
  'reactos-distro:nightly-x86_64:raw:reactos' \
  'unikernel-distro:unikernel-unikraft-redis:uefi-gpt:unikernel'; do
  _dt="${_spec%%:*}"
  _rem="${_spec#*:}"
  _prof="${_rem%%:*}"
  _rem2="${_rem#*:}"
  _fmt="${_rem2%%:*}"
  _fam="${_rem2#*:}"
  _art="${_tmp}/${_dt}.${_fmt}"

  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as "$_dt" --profile "$_prof" --format "$_fmt" --output "$_art" --allow-stub >/dev/null
  STACK='' "${SCRIPT_DIR}/cli.sh" distro --disk="$_art" --clouds=aws,gcp,azure --dry-run >/dev/null
  _out2=$(STACK='' "${SCRIPT_DIR}/cli.sh" distro --disk="$_art" --clouds=aws,gcp,azure --dry-run)
  case "$_out2" in
    *'[SKIP]'*) ;;
    *)
      printf '[FAIL] Expected [SKIP] on 2nd run for %s\n' "$_dt" >&2
      exit 1
      ;;
  esac
  jq -e --arg f "$_fam" '.registrations.aws.distro_family == $f and .registrations.gcp.distro_family == $f and .registrations.azure.distro_family == $f and (.registrations.azure.managed_image_id | length > 0)' \
    "${_art}.multicloud-receipt.json" >/dev/null
done

printf '%s\n' '[PASS] image-import multicloud distro artifact & 2x-idempotency tests passed.'
