#!/bin/sh
# ## Overview
# Runs tests sequentially for LibScript components on a local FreeDOS Vagrant VM (`bento/freedos-1.3`
# or `bento/freedos-1.4`) using `Bento::VagrantFreedos` (`:freedos` serial communicator + `:freedos_sync`
# `D:` drive), `vanilla` snapshot restoration, and 2x idempotency verification.
#
# ## Usage
# ./tests/run_freedos_tests.sh [TARGETS...|all] [--os freedos-1.3|freedos-1.4] [--snapshot vanilla] [--boot-only]

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

# ## resolve_default_freedos_os
# Chooses `freedos-1.4` if its `.qemu.box` exists in `../bento/builds/build_complete/`, otherwise `freedos-1.3`.
resolve_default_freedos_os() {
  _bdir="${BENTO_DIR:-${LIBSCRIPT_ROOT_DIR}/../bento}"
  for _a in aarch64 x86_64 i386; do
    if [ -f "${_bdir}/builds/build_complete/freedos-1.4-${_a}.qemu.box" ]; then
      printf '%s\n' 'freedos-1.4'
      return 0
    fi
  done
  printf '%s\n' 'freedos-1.3'
}

FREEDOS_OS=$(resolve_default_freedos_os)
FORWARD_ARGS=""

# ## show_freedos_help
# Displays CLI usage help for run_freedos_tests.sh.
show_freedos_help() {
  printf 'Usage: %s [TARGETS...|all] [--os freedos-1.3|freedos-1.4] [--snapshot vanilla] [--idempotency-runs 2] [--boot-only]\n' "$0"
  printf 'Runs LibScript DOS component verification on a local Bento FreeDOS Vagrant VM.\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|/\?|-\?)
      show_freedos_help
      exit 0
      ;;
    --os|--target-os)
      FREEDOS_OS="$2"
      shift 2
      ;;
    --os=*|--target-os=*)
      FREEDOS_OS="${1#*=}"
      shift
      ;;
    *)
      FORWARD_ARGS="${FORWARD_ARGS} $1"
      shift
      ;;
  esac
done

# shellcheck disable=SC2086
STACK="" exec "${SCRIPT_DIR}/run_local_tests.sh" --os "${FREEDOS_OS}" --reuse-vm ${FORWARD_ARGS}
