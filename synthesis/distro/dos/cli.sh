#!/bin/sh
# ## Overview
# CLI router for synthesis/distro/dos supporting assemble, install, test, and uninstall actions.
#
# ## Usage
# ./synthesis/distro/dos/cli.sh <assemble|install|test|uninstall> [args...]

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

ACT="${1:-${ACTION:-assemble}}"
shift || true
case "${ACT}" in
  install|bootstrap)
    case "${1:-}" in
      latest|stable) shift || true ;;
    esac
    STACK='' "${SCRIPT_DIR}/assemble.sh" "$@"
    ;;
  assemble|compile) STACK='' "${SCRIPT_DIR}/assemble.sh" "$@" ;;
  test) STACK='' "${SCRIPT_DIR}/test.sh" "$@" ;;
  uninstall) STACK='' "${SCRIPT_DIR}/uninstall.sh" "$@" ;;
  --help|-h) printf 'Usage: %s <assemble|install|test|uninstall> [sysroot] [out_img]\n' "${THIS_FILE}" ;;
  *) STACK='' "${SCRIPT_DIR}/assemble.sh" "$@" ;;
esac
