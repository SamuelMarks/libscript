#!/bin/sh
# ## Overview
# Command-line interface entry point for Bento Builder stack, supporting standard Version Manager verbs
# via `component_core.sh` plus `build`, `box`, and `register` delegation to `setup_generic.sh`.
#
# ## Usage
# ./synthesis/distro/bento/cli.sh [install|build|box|register|test|ls|use|uninstall] [args...]

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

case "${1:-}" in
  build|box|register)
    ACTION="$1"
    shift
    while [ $# -gt 0 ]; do
      case "$1" in
        --bento-dir)
          BENTO_DIR="$2"
          export BENTO_DIR
          shift 2
          ;;
        --bento-dir=*)
          BENTO_DIR="${1#*=}"
          export BENTO_DIR
          shift
          ;;
        --force|--force-rebuild)
          BENTO_BUILDER_FORCE_REBUILD='1'
          export BENTO_BUILDER_FORCE_REBUILD
          shift
          ;;
        -*)
          shift
          ;;
        *)
          if [ -z "${BENTO_BUILDER_TARGET_OS:-}" ]; then
            BENTO_BUILDER_TARGET_OS="$1"
            export BENTO_BUILDER_TARGET_OS
          fi
          shift
          ;;
      esac
    done
    export ACTION
    unset SCRIPT_NAME || true
    exec "${SCRIPT_DIR}/setup_generic.sh"
    ;;
esac

export PACKAGE_NAME='bento-builder'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
