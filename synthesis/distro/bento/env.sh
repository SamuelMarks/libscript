#!/bin/sh
# ## Overview
# Environment configuration for Bento Builder stack, exporting `BENTO_DIR` and `RUBYLIB` so
# `Bento::VagrantMsdos` and `Bento::VagrantFreedos` load cleanly inside Vagrant without global gem pollution.
#
# ## Usage
# Source this file to configure the Bento Builder environment.

set -feu; _env_caller_this="${THIS_FILE:-}"; _env_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "${_env_caller_dir:-}" ] && SCRIPT_DIR="${_env_caller_dir}"; [ -n "${_env_caller_this:-}" ] && THIS_FILE="${_env_caller_this}"; unset SCRIPT_NAME _env_caller_this _env_caller_dir || true
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
THIS_FILE="${_EB_CALLER_THIS}"
SCRIPT_DIR="${_EB_CALLER_DIR}"

if [ -z "${BENTO_DIR:-}" ]; then
  for _b_cand in "${LIBSCRIPT_ROOT_DIR}/../bento" "${HOME:-/root}/bento"; do
    if [ -f "${_b_cand}/bento.gemspec" ] || [ -f "${_b_cand}/builds.yml" ] || [ -d "${_b_cand}/os_pkrvars" ]; then
      BENTO_DIR=$(cd -- "${_b_cand}" && pwd)
      export BENTO_DIR
      break
    fi
  done
elif [ -d "${BENTO_DIR}" ]; then
  BENTO_DIR=$(cd -- "${BENTO_DIR}" && pwd)
  export BENTO_DIR
fi

if [ -n "${BENTO_DIR:-}" ] && [ -d "${BENTO_DIR}/lib" ]; then
  case ":${RUBYLIB:-}:" in
    *":${BENTO_DIR}/lib:"*) ;;
    *)
      if [ -n "${RUBYLIB:-}" ]; then
        RUBYLIB="${BENTO_DIR}/lib:${RUBYLIB}"
      else
        RUBYLIB="${BENTO_DIR}/lib"
      fi
      export RUBYLIB
      ;;
  esac
fi

export INSTALL_QEMU="${INSTALL_QEMU:-1}"
export INSTALL_VIRTUALBOX="${INSTALL_VIRTUALBOX:-1}"
export INSTALL_PACKER="${INSTALL_PACKER:-1}"
export INSTALL_VAGRANT="${INSTALL_VAGRANT:-1}"
export INSTALL_IMAGE_TOOLS="${INSTALL_IMAGE_TOOLS:-1}"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_env_caller_dir:-}" ] && SCRIPT_DIR="${_env_caller_dir}"; [ -n "${_env_caller_this:-}" ] && THIS_FILE="${_env_caller_this}"; unset SCRIPT_NAME _env_caller_this _env_caller_dir || true
