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
for LIB in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

PYTHON_INSTALL_METHOD="${PYTHON_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-uv}}"

if [ "${PYTHON_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'python'
elif [ "${PYTHON_INSTALL_METHOD}" = 'pyenv' ]; then
  libscript_depends 'git'
  if [ ! -d "${HOME}/.pyenv" ]; then
    INSTALL_SH=$(mktemp)
    libscript_download 'https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer' "${INSTALL_SH}"
    bash "${INSTALL_SH}"
    rm -f "${INSTALL_SH}"
  fi
  export PYENV_ROOT="${HOME}/.pyenv"
  export PATH="${PYENV_ROOT}/bin:${PATH}"
  eval "$(pyenv init -)"
  pyenv install -s "${PYTHON_VERSION:-3.11}"
  pyenv global "${PYTHON_VERSION:-3.11}"
elif [ "${PYTHON_INSTALL_METHOD}" = 'from-source' ]; then
  libscript_depends 'build-essential' 'libssl-dev' 'zlib1g-dev' 'libbz2-dev' 'libreadline-dev' 'libsqlite3-dev' 'wget' 'curl' 'llvm' 'libncurses5-dev' 'libncursesw5-dev' 'xz-utils' 'tk-dev' 'libffi-dev' 'liblzma-dev'
  PY_VER="${PYTHON_VERSION:-3.11.9}"
  PY_TARBALL=$(mktemp)
  libscript_download "https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tgz" "${PY_TARBALL}"
  tar -xf "${PY_TARBALL}"
  rm -f "${PY_TARBALL}"
  cd "Python-${PY_VER}"
  ./configure --enable-optimizations
  make -j"$(nproc)"
  sudo make altinstall
  cd ..
  rm -rf "Python-${PY_VER}"
else # uv
  if [ ! -f "${HOME}"'/.local/bin/uv' ]; then
    INSTALL_SH=$(mktemp)
    libscript_download 'https://astral.sh/uv/install.sh' "${INSTALL_SH}"
    sh "${INSTALL_SH}"
    rm -f "${INSTALL_SH}"
  fi
  # shellcheck disable=SC1091

  # uv python install "${PYTHON_VERSION}"
  if [ "${PYTHON_VENV-}" ] && [ "${PYTHON_VENV-}" ]; then
    export VENV="${PYTHON_VENV}"
  fi
  if [ "${PYTHON_VENV-}" ] && [ ! -f "${PYTHON_VENV}"'/bin/python' ]; then
    if [ "${PYTHON_VERSION:-3.11}" = "latest" ]; then
      uv venv "${PYTHON_VENV}"
    else
      uv venv --python "${PYTHON_VERSION:-3.11}" "${PYTHON_VENV}"
    fi
    "${PYTHON_VENV}"'/bin/python' -m ensurepip
    "${PYTHON_VENV}"'/bin/python' -m pip install -U pip
    "${PYTHON_VENV}"'/bin/python' -m pip install -U setuptools wheel
    # For safety only install package and its deps inside a venv
    if [ -f 'requirements.txt' ]; then
      "${PYTHON_VENV}"'/bin/python' -m pip install -r 'requirements.txt'
    fi
    if [ -f 'setup.py' ] || [ -f 'setup.cfg' ] || [ -f 'pyproject.toml' ]; then
      "${PYTHON_VENV}"'/bin/python' -m pip install -e .
    fi
  fi
fi
