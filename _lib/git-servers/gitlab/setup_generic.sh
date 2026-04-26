#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

GITLAB_INSTALL_METHOD="${GITLAB_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${GITLAB_INSTALL_METHOD}" = 'system' ]; then
  if command -v apt-get >/dev/null 2>&1; then
    INSTALL_SH=$(mktemp)
    libscript_download 'https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh' "${INSTALL_SH}"
    sudo bash "${INSTALL_SH}"
    rm -f "${INSTALL_SH}"
    sudo apt-get install -y gitlab-ce
  elif command -v yum >/dev/null 2>&1; then
    INSTALL_SH=$(mktemp)
    libscript_download 'https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh' "${INSTALL_SH}"
    sudo bash "${INSTALL_SH}"
    rm -f "${INSTALL_SH}"
    sudo yum install -y gitlab-ce
  else
    depends 'gitlab-ce'
  fi
else
  echo "[WARN] From-source or alternative installation requested for GitLab CE."
  echo "[ERROR] GitLab CE source installation is extremely complex and not supported directly via pure sh scripts."
  echo "Please use the 'system' installation method or use Docker."
  exit 1
fi
