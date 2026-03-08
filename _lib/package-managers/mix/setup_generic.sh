#!/bin/sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

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
      depends elixir || true
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
