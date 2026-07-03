#!/bin/sh
# ## Overview
# Generic setup module for GitLab.
#
# ## Usage
# Installs GitLab CE via omnibus package using the official repository scripts.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

GITLAB_INSTALL_METHOD="${GITLAB_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${GITLAB_INSTALL_METHOD}" = 'system' ]; then
  if command -v apt >/dev/null 2>&1; then
    INSTALL_SH=$(mktemp)
    libscript_download 'https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh' "${INSTALL_SH}"
    if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" != "1" ]; then
      sudo bash "${INSTALL_SH}"
    fi
    rm -f "${INSTALL_SH}"
    pkg_mgr install gitlab-ce
  elif command -v yum >/dev/null 2>&1; then
    INSTALL_SH=$(mktemp)
    libscript_download 'https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh' "${INSTALL_SH}"
    if [ "${LIBSCRIPT_SKIP_SYSTEM_DEPS:-0}" != "1" ]; then
      sudo bash "${INSTALL_SH}"
    fi
    rm -f "${INSTALL_SH}"
    pkg_mgr install gitlab-ce
  else
    libscript_depends 'gitlab-ce'
  fi
else
  log_info "[WARN] From-source or alternative installation requested for GitLab CE."
  log_info "[ERROR] GitLab CE source installation is extremely complex and not supported directly via pure sh scripts."
  log_info "Please use the 'system' installation method or use Docker."
  exit 1
fi
