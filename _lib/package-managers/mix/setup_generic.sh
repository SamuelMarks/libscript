#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-..}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if ! command -v mix >/dev/null 2>&1; then
  if command -v elixir >/dev/null 2>&1; then
    # Usually mix comes with elixir, maybe it's not in path.
    :
  else
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/elixir/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/languages/elixir/setup.sh"
    else
      if ! depends elixir ; then
        true
      fi
    fi
  fi
fi

if ! command -v mix >/dev/null 2>&1; then
  if command -v asdf >/dev/null 2>&1; then
    asdf plugin-add elixir || true
    asdf install elixir latest
    asdf global elixir latest
  fi
fi

# Ensure local mix hex is available
if command -v mix >/dev/null 2>&1; then
  mix local.hex --force || true
  mix local.rebar --force || true
fi
