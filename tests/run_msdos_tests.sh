#!/bin/sh
# ## Overview
# Runs tests sequentially for LibScript components on a local Microsoft MS-DOS Vagrant VM
# (`bento/msdos-4.0`, `bento/msdos-2.0`, or `bento/msdos-1.25`) using `Bento::VagrantMsdos`
# (`:msdos` serial communicator + `:msdos_sync` `D:` drive), `vanilla` snapshot restoration, and 2x idempotency.
#
# ## Usage
# ./tests/run_msdos_tests.sh [TARGETS...|all] [--os msdos-4.0|msdos-2.0|msdos-1.25] [--snapshot vanilla] [--boot-only]

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

MSDOS_OS="${MSDOS_OS:-msdos-4.0}"
FORWARD_ARGS=""

# ## show_msdos_help
# Displays CLI usage help for run_msdos_tests.sh.
show_msdos_help() {
  printf 'Usage: %s [TARGETS...|all] [--os msdos-4.0|msdos-2.0|msdos-1.25] [--snapshot vanilla] [--idempotency-runs 2] [--boot-only]\n' "$0"
  printf 'Runs LibScript DOS component verification on a local Bento MS-DOS Vagrant VM.\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|/\?|-\?)
      show_msdos_help
      exit 0
      ;;
    --os|--target-os)
      MSDOS_OS="$2"
      shift 2
      ;;
    --os=*|--target-os=*)
      MSDOS_OS="${1#*=}"
      shift
      ;;
    *)
      FORWARD_ARGS="${FORWARD_ARGS} $1"
      shift
      ;;
  esac
done

# shellcheck disable=SC2086
STACK="" exec "${SCRIPT_DIR}/run_local_tests.sh" --os "${MSDOS_OS}" --reuse-vm ${FORWARD_ARGS}
