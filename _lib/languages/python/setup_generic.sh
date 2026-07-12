#!/bin/sh
# ## Overview
# Generic setup module for Python.
#
# ## Usage
# Installs Python by compiling from source or by delegating to system/mise/asdf. Can also create venvs.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

PYTHON_INSTALL_METHOD="$(libscript_resolve_install_method "PYTHON")"
PYTHON_VERSION="${PYTHON_VERSION:-3.11.9}"
ACTION="${ACTION:-install}"

resolve_exact_version() {
  if [ "${PYTHON_VERSION}" = "latest" ]; then
    EXACT_VERSION=$(curl -sL https://www.python.org/ftp/python/ | grep -o 'href="3\.[0-9]*\.[0-9]*/"' | sed 's/href="//' | sed 's/\/"//' | sort -V | tail -n 1)
  else
    EXACT_VERSION="${PYTHON_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$PYTHON_INSTALL_METHOD" = "mise" ]; then
      mise ls python
    elif [ "$PYTHON_INSTALL_METHOD" = "asdf" ]; then
      asdf list python
    elif [ "$PYTHON_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$PYTHON_INSTALL_METHOD" = "vfox" ]; then
      vfox ls python
    elif [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      python3 --version
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/python/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$PYTHON_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote python
    elif [ "$PYTHON_INSTALL_METHOD" = "asdf" ]; then
      asdf list all
    elif [ "$PYTHON_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$PYTHON_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all python
    elif [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System package manager does not support ls-remote directly here."
    else
      curl -sL https://www.python.org/ftp/python/ | grep -o 'href="[0-9]*\.[0-9]*\.[0-9]*/"' | sed 's/href="//' | sed 's/\/"//' | sort -V
    fi
    exit 0
    ;;
  use)
    if [ "$PYTHON_INSTALL_METHOD" = "mise" ]; then
      mise use "python@${PYTHON_VERSION}"
    elif [ "$PYTHON_INSTALL_METHOD" = "asdf" ]; then
      asdf global python "${PYTHON_VERSION}"
    elif [ "$PYTHON_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$PYTHON_INSTALL_METHOD" = "vfox" ]; then
      vfox use "python@${PYTHON_VERSION}"
    elif [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "Cannot 'use' specific version with system package manager."
    else
      resolve_exact_version
      libscript_symlink_alias "python" "${PYTHON_VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias "python" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/python/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "python ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "python" "default" "${EXACT_VERSION}"
      log_info "Set default python version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env python \"${PYTHON_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading python ${PYTHON_VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python"
      if [ -n "${PYTHON_DOWNLOAD_URL:-}" ]; then
        libscript_download "${PYTHON_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python/python-${VERSION}.tar.gz"
      else
        log_warn "PYTHON_DOWNLOAD_URL is not defined for python ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)

    if [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'python'
    elif [ "$PYTHON_INSTALL_METHOD" = "mise" ]; then
      mise install "python@${PYTHON_VERSION}"
    elif [ "$PYTHON_INSTALL_METHOD" = "asdf" ]; then
      asdf install python "${PYTHON_VERSION}"
    elif [ "$PYTHON_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "python@${PYTHON_VERSION}"
    elif [ "$PYTHON_INSTALL_METHOD" = "vfox" ]; then
      vfox add python || true
      vfox install "python@${PYTHON_VERSION}"
    else
      resolve_exact_version
      PY_DIR=$(libscript_get_version_dir "python" "${EXACT_VERSION}")
      export PATH="${PY_DIR}/bin:${PATH}"
      
      PY_MINOR_VER=$(printf '%s\n' "$EXACT_VERSION" | cut -d. -f1,2)
      if [ -x "${PY_DIR}/bin/python${PY_MINOR_VER}" ]; then
        libscript_symlink_alias "python" "${PYTHON_VERSION}" "${EXACT_VERSION}"
        if [ ! -f "${PY_DIR}/bin/python" ]; then
          ln -sf "python${PY_MINOR_VER}" "${PY_DIR}/bin/python"
        fi
        if [ ! -f "${PY_DIR}/bin/python3" ]; then
          ln -sf "python${PY_MINOR_VER}" "${PY_DIR}/bin/python3"
        fi
      else
        if command -v apt-get >/dev/null 2>&1; then
          libscript_depends 'build-essential' 'libssl-dev' 'zlib1g-dev' 'libbz2-dev' 'libreadline-dev' 'libsqlite3-dev' 'wget' 'curl' 'llvm' 'libncurses5-dev' 'libncursesw5-dev' 'xz-utils' 'tk-dev' 'libffi-dev' 'liblzma-dev'
        elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
          libscript_depends 'gcc' 'make' 'openssl-devel' 'bzip2-devel' 'libffi-devel' 'zlib-devel' 'readline-devel' 'sqlite-devel' 'wget' 'curl' 'xz-devel'
        else
          libscript_depends 'wget' 'curl' 'xz' 'openssl' 'readline' 'sqlite3'
        fi
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python/"*"${EXACT_VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python/" -maxdepth 1 -type f -name "*${EXACT_VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            TMP_BUILD_DIR=$(mktemp -d)
            tar -xf "$cache_file" -C "${TMP_BUILD_DIR}" || true
          fi
        else
          PY_TARBALL=$(mktemp)
        libscript_download "https://www.python.org/ftp/python/${EXACT_VERSION}/Python-${EXACT_VERSION}.tgz" "${PY_TARBALL}"
        TMP_BUILD_DIR=$(mktemp -d)
        tar -xf "${PY_TARBALL}" -C "${TMP_BUILD_DIR}"
        rm -f "${PY_TARBALL}"
        fi
        
        mkdir -p "${PY_DIR}"
        (
          cd "${TMP_BUILD_DIR}/Python-${EXACT_VERSION}" || exit 1
          if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
            ./configure --prefix="${PY_DIR}" --enable-optimizations --with-openssl="$(brew --prefix openssl)" --with-system-zlib
          else
            ./configure --prefix="${PY_DIR}" --enable-optimizations
          fi
          make -j"$(nproc 2>/dev/null || printf '%s\n' 2)"
          make altinstall
        )
        rm -rf "${TMP_BUILD_DIR}"
        
        # Setup symlinks
        if [ ! -f "${PY_DIR}/bin/python" ] && [ -f "${PY_DIR}/bin/python${PY_MINOR_VER}" ]; then
          ln -sf "python${PY_MINOR_VER}" "${PY_DIR}/bin/python"
        fi
        if [ ! -f "${PY_DIR}/bin/python3" ] && [ -f "${PY_DIR}/bin/python${PY_MINOR_VER}" ]; then
          ln -sf "python${PY_MINOR_VER}" "${PY_DIR}/bin/python3"
        fi
        
        # Install ensurepip if pip isn't installed
        if [ -x "${PY_DIR}/bin/python" ] && ! "${PY_DIR}/bin/python" -m pip --version >/dev/null 2>&1; then
           "${PY_DIR}/bin/python" -m ensurepip || true
        fi
        
        libscript_symlink_alias "python" "${PYTHON_VERSION}" "${EXACT_VERSION}"
      fi

      # VENV logic from old script
      if [ "${PYTHON_VENV-}" ]; then
        export VENV="${PYTHON_VENV}"
        if [ ! -f "${PYTHON_VENV}/bin/python" ]; then
          "${PY_DIR}/bin/python" -m venv "${PYTHON_VENV}"
          "${PYTHON_VENV}/bin/python" -m pip install -U pip setuptools wheel
          
          # Hardware-Optimized ML Profiles
          if [ -n "${ML_ACCELERATOR_BACKEND:-}" ]; then
            log_info "Installing hardware-optimized ML profile: ${ML_ACCELERATOR_BACKEND}"
            case "${ML_ACCELERATOR_BACKEND}" in
              tpu-jax)
                "${PYTHON_VENV}/bin/python" -m pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html
                ;;
              tpu-maxtext)
                "${PYTHON_VENV}/bin/python" -m pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html maxtext
                ;;
              tpu-keras)
                "${PYTHON_VENV}/bin/python" -m pip install jax[tpu] -f https://storage.googleapis.com/jax-releases/libtpu_releases.html keras
                ;;
              tpu-torch)
                "${PYTHON_VENV}/bin/python" -m pip install torch~=2.2.0 torch_xla[tpu]~=2.2.0 -f https://storage.googleapis.com/libtpu-releases/index.html
                ;;
              gpu-cuda12)
                "${PYTHON_VENV}/bin/python" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
                ;;
              gpu-jax)
                "${PYTHON_VENV}/bin/python" -m pip install "jax[cuda12]"
                ;;
              *)
                log_warn "Unknown ML_ACCELERATOR_BACKEND: ${ML_ACCELERATOR_BACKEND}. Skipping."
                ;;
            esac
          fi
          
          if [ -f 'requirements.txt' ]; then
            "${PYTHON_VENV}/bin/python" -m pip install -r 'requirements.txt'
          fi
          if [ -f 'setup.py' ] || [ -f 'setup.cfg' ] || [ -f 'pyproject.toml' ]; then
            "${PYTHON_VENV}/bin/python" -m pip install -e .
          fi
        fi
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ] || [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-python}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $PYTHON_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ] || [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-python}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $PYTHON_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ] || [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-python}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $PYTHON_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling python $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/python/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/python/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $PYTHON_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
