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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
[ -z "${LIBSCRIPT_ROOT_DIR:-}" ] && LIBSCRIPT_ROOT_DIR=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; echo "$d")
for LIB in "_lib/_common/pkg_mgr.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
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
  PY_VER="${PYTHON_VERSION:-3.11.9}"
  PY_MINOR_VER=$(echo "$PY_VER" | cut -d. -f1,2)
  if command -v "python${PY_MINOR_VER}" >/dev/null 2>&1; then
    log_info "Python ${PY_MINOR_VER} is already installed from source or system. Skipping."
  else
    libscript_depends 'build-essential' 'libssl-dev' 'zlib1g-dev' 'libbz2-dev' 'libreadline-dev' 'libsqlite3-dev' 'wget' 'curl' 'llvm' 'libncurses5-dev' 'libncursesw5-dev' 'xz-utils' 'tk-dev' 'libffi-dev' 'liblzma-dev'
    PY_TARBALL=$(mktemp)
    libscript_download "https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tgz" "${PY_TARBALL}"
    TMP_BUILD_DIR=$(mktemp -d)
    tar -xf "${PY_TARBALL}" -C "${TMP_BUILD_DIR}"
    rm -f "${PY_TARBALL}"
    (
      cd "${TMP_BUILD_DIR}/Python-${PY_VER}" || exit 1
      ./configure --enable-optimizations
      make -j"$(nproc)"
      sudo make altinstall
    )
    rm -rf "${TMP_BUILD_DIR}"
  fi
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
    
    # Hardware-Optimized ML Profiles
    if [ -n "${ML_ACCELERATOR_BACKEND:-}" ]; then
      log_info "Installing hardware-optimized ML profile: ${ML_ACCELERATOR_BACKEND}"
      case "${ML_ACCELERATOR_BACKEND}" in
        tpu-jax)
          "${PYTHON_VENV}"'/bin/python' -m pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html
          ;;
        tpu-maxtext)
          "${PYTHON_VENV}"'/bin/python' -m pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html
          "${PYTHON_VENV}"'/bin/python' -m pip install maxtext
          ;;
        tpu-keras)
          "${PYTHON_VENV}"'/bin/python' -m pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html
          "${PYTHON_VENV}"'/bin/python' -m pip install keras
          ;;
        tpu-torch)
          "${PYTHON_VENV}"'/bin/python' -m pip install torch~=2.2.0 torch_xla[tpu]~=2.2.0 -f https://storage.googleapis.com/libtpu-releases/index.html
          ;;
        gpu-cuda12)
          "${PYTHON_VENV}"'/bin/python' -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
          ;;
        gpu-jax)
          "${PYTHON_VENV}"'/bin/python' -m pip install "jax[cuda12]"
          ;;
        *)
          log_warn "Unknown ML_ACCELERATOR_BACKEND: ${ML_ACCELERATOR_BACKEND}. Skipping."
          ;;
      esac
    fi
    
    # For safety only install package and its deps inside a venv
    if [ -f 'requirements.txt' ]; then
      "${PYTHON_VENV}"'/bin/python' -m pip install -r 'requirements.txt'
    fi
    if [ -f 'setup.py' ] || [ -f 'setup.cfg' ] || [ -f 'pyproject.toml' ]; then
      "${PYTHON_VENV}"'/bin/python' -m pip install -e .
    fi
  fi
fi
