#!/bin/sh
# ## Overview
# Thin declarative entrypoint for the Open edX installer-e2e experiment delegating to pkg_ui_runner.sh.
# ## Usage
# ./experiments/openedx/run.sh [--target-os=<os>] [--bento-prefix=<prefix>] [--pkg-format=<fmt>] [--pkg-source=github-release|build] [--install-modes=headless,quick,custom] [--dry-run=1]
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
export LIBSCRIPT_ROOT_DIR

STACK='' exec sh "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/pkg_ui_runner.sh" --suite-dir="${SCRIPT_DIR}" "$@"
