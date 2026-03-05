#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

PYTHON_INSTALL_METHOD="${PYTHON_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-uv}}"

if [ "${PYTHON_INSTALL_METHOD}" = 'system' ]; then
  depends 'python'
elif [ "${PYTHON_INSTALL_METHOD}" = 'pyenv' ]; then
  depends 'curl' 'git'
  if [ ! -d "${HOME}/.pyenv" ]; then
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
  fi
  export PYENV_ROOT="${HOME}/.pyenv"
  export PATH="${PYENV_ROOT}/bin:${PATH}"
  eval "$(pyenv init -)"
  pyenv install -s "${PYTHON_VERSION:-3.11}"
  pyenv global "${PYTHON_VERSION:-3.11}"
elif [ "${PYTHON_INSTALL_METHOD}" = 'from-source' ]; then
  depends 'curl' 'build-essential' 'libssl-dev' 'zlib1g-dev' 'libbz2-dev' 'libreadline-dev' 'libsqlite3-dev' 'wget' 'curl' 'llvm' 'libncurses5-dev' 'libncursesw5-dev' 'xz-utils' 'tk-dev' 'libffi-dev' 'liblzma-dev'
  PY_VER="${PYTHON_VERSION:-3.11.9}"
  libscript_download "https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tgz" ""
  tar -xf "Python-${PY_VER}.tgz"
  cd "Python-${PY_VER}"
  ./configure --enable-optimizations
  make -j"$(nproc)"
  sudo make altinstall
  cd ..
  rm -rf "Python-${PY_VER}" "Python-${PY_VER}.tgz"
else # uv
  depends 'curl'
  if [ ! -f "${HOME}"'/.local/bin/uv' ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi
  # shellcheck disable=SC1091
  
  # uv python install "${PYTHON_VERSION}"
  if [ "${VENV-}" ] && [ "${PYTHON_VENV-}" ]; then
    export VENV="${PYTHON_VENV}"
  fi
  if [ "${VENV-}" ] && [ ! -f "${VENV}"'/bin/python' ]; then
    if [ "${PYTHON_VERSION:-3.11}" = "latest" ]; then
      uv venv "${VENV}"
    else
      uv venv --python "${PYTHON_VERSION:-3.11}" "${VENV}"
    fi
    "${VENV}"'/bin/python' -m ensurepip
    "${VENV}"'/bin/python' -m pip install -U pip
    "${VENV}"'/bin/python' -m pip install -U setuptools wheel
    # For safety only install package and its deps inside a venv
    if [ -f 'requirements.txt' ]; then
      "${VENV}"'/bin/python' -m pip install -r 'requirements.txt'
    fi
    if [ -f 'setup.py' ] || [ -f 'setup.cfg' ] || [ -f 'pyproject.toml' ]; then
      "${VENV}"'/bin/python' -m pip install -e .
    fi
  fi
fi
