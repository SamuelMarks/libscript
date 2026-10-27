#!/bin/sh
# ## Overview
# Generic setup module for Python.
#
# ## Usage
# Reuses existing matching Python installations or installs via uv/system/source. Can also create venvs.


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
export DIR="${SCRIPT_DIR}"

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

PYTHON_INSTALL_METHOD="${PYTHON_INSTALL_METHOD:-libscript_native}"
PYTHON_VERSION="${PYTHON_VERSION:-${VERSION:-3.12}}"
ACTION="${ACTION:-install}"

# Parse python and pip offline options
while [ $# -gt 0 ]; do
  case "$1" in
    --offline|-o) export LIBSCRIPT_OFFLINE=1; shift ;;
    --pip-find-links=*) export PIP_FIND_LINKS="${1#*=}"; shift ;;
    --pip-find-links) export PIP_FIND_LINKS="${2:-}"; shift 2 ;;
    --pip-no-index) export PIP_NO_INDEX=1; shift ;;
    --pip-wheel-dir=*) export PIP_WHEEL_DIR="${1#*=}"; shift ;;
    --pip-wheel-dir) export PIP_WHEEL_DIR="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ] || [ "${PIP_NO_INDEX:-0}" = "1" ]; then
  export PIP_NO_INDEX=1
  _def_wheels="${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache}/wheels"
  export PIP_FIND_LINKS="${PIP_FIND_LINKS:-${PIP_WHEEL_DIR:-$_def_wheels}}"
fi

# ## find_existing_python
# Searches LIBSCRIPT_HOME, system PATH, and uv python directories for a Python interpreter matching PYTHON_VERSION.
find_existing_python() {
  _fep_req=$(printf '%s' "$PYTHON_VERSION" | cut -d. -f1,2)
  [ "$_fep_req" = "latest" ] && _fep_req="3.12"
  _fep_home="${LIBSCRIPT_HOME:-$HOME/.libscript}"
  if [ -x "${_fep_home}/python/${PYTHON_VERSION}/bin/python3" ]; then
    printf '%s\n' "${_fep_home}/python/${PYTHON_VERSION}/bin/python3"
    return 0
  fi
  if command -v "python${_fep_req}" >/dev/null 2>&1; then
    command -v "python${_fep_req}"
    return 0
  fi
  for _fep_uv_dir in "${UV_PYTHON_INSTALL_DIR:-}" "${REMOTE_HOME:-$HOME}/.local/share/uv/python" "${HOME}/.local/share/uv/python" "/root/.local/share/uv/python"; do
    [ -n "$_fep_uv_dir" ] && [ -d "$_fep_uv_dir" ] || continue
    for _fep_cand in "$_fep_uv_dir"/cpython-"${_fep_req}"*/bin/python3; do
      if [ -x "$_fep_cand" ]; then
        printf '%s\n' "$_fep_cand"
        return 0
      fi
    done
  done
  if command -v uv >/dev/null 2>&1; then
    _uv_found=$(uv python find "$_fep_req" 2>/dev/null || true)
    if [ -n "$_uv_found" ] && [ -x "$_uv_found" ]; then
      printf '%s\n' "$_uv_found"
      return 0
    fi
  fi
  if command -v python3 >/dev/null 2>&1; then
    _sys_pyv=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2 || true)
    if [ "$_sys_pyv" = "$_fep_req" ]; then
      command -v python3
      return 0
    fi
  fi
  return 1
}

# ## link_python_into_libscript_home
# Symlinks a discovered Python binary directory into LIBSCRIPT_HOME/python/<PYTHON_VERSION>.
link_python_into_libscript_home() {
  _lpi_py_bin="$1"
  _lpi_bin_dir=$(dirname -- "$_lpi_py_bin")
  _lpi_target="${LIBSCRIPT_HOME:-$HOME/.libscript}/python/${PYTHON_VERSION}"
  mkdir -p "${_lpi_target}/bin"
  if [ "$_lpi_py_bin" != "${_lpi_target}/bin/python3" ]; then
    ln -sf "$_lpi_py_bin" "${_lpi_target}/bin/python3" 2>/dev/null || true
    ln -sf "$_lpi_py_bin" "${_lpi_target}/bin/python" 2>/dev/null || true
    _lpi_minor=$(printf '%s' "$PYTHON_VERSION" | cut -d. -f1,2)
    ln -sf "$_lpi_py_bin" "${_lpi_target}/bin/python${_lpi_minor}" 2>/dev/null || true
    if [ -x "${_lpi_bin_dir}/pip3" ]; then
      ln -sf "${_lpi_bin_dir}/pip3" "${_lpi_target}/bin/pip3" 2>/dev/null || true
      ln -sf "${_lpi_bin_dir}/pip3" "${_lpi_target}/bin/pip" 2>/dev/null || true
    fi
  fi
  libscript_symlink_alias "python" "default" "${PYTHON_VERSION}"
  libscript_symlink_alias "python" "latest" "${PYTHON_VERSION}"
  _py_owner="${SERVICE_USER:-${REMOTE_USER:-${SUDO_USER:-}}}"
  if [ -n "$_py_owner" ] && [ "$_py_owner" != "root" ]; then
    chmod 0755 "${LIBSCRIPT_HOME:-$HOME/.libscript}" "${LIBSCRIPT_HOME:-$HOME/.libscript}/python" 2>/dev/null || true
    chown -R "${_py_owner}:${SERVICE_GROUP:-${REMOTE_GROUP:-$_py_owner}}" "${LIBSCRIPT_HOME:-$HOME/.libscript}/python" 2>/dev/null || true
  fi
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${PYTHON_VERSION}" = "latest" ]; then
    if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
      EXACT_VERSION='3.12.8'
    else
      EXACT_VERSION=$(libscript_fetch_stdout "https://www.python.org/downloads/" | grep -o 'Python 3\.[0-9]*\.[0-9]*' | libscript_sort_versions | tail -n 1 | awk '{print $2}')
      [ -z "$EXACT_VERSION" ] && EXACT_VERSION="3.12.8"
    fi
  elif ! printf '%s' "$PYTHON_VERSION" | grep -q '\.[0-9]*\.'; then
    EXACT_VERSION="${PYTHON_VERSION}.8"
  else
    EXACT_VERSION="${PYTHON_VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      python3 --version 2>/dev/null || true
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/python/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' 'System package manager does not support ls-remote directly here.'
    else
      libscript_fetch_stdout "https://www.python.org/ftp/python/" | grep -o 'href="[0-9]*\.[0-9]*\.[0-9]*/"' | sed 's/href="//' | sed 's/\/"//' | libscript_sort_versions
    fi
    exit 0
    ;;
  use)
    if [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
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
      log_info 'To apply to the current shell, run:'
      log_info "  . \"${DIR}/env.sh\" # or: . \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env python \"${PYTHON_VERSION}\")"
    fi
    exit 0
    ;;
  download)
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_python >/dev/null 2>&1; then
        log_info "[REUSE] Python ${PYTHON_VERSION} is already installed; skipping download."
        exit 0
      fi
      log_info "Downloading python ${PYTHON_VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python"
      if [ -n "${PYTHON_DOWNLOAD_URL:-}" ]; then
        libscript_download "${PYTHON_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python/python-${PYTHON_VERSION}.tar.gz"
      else
        log_warn "PYTHON_DOWNLOAD_URL is not defined for python ${PYTHON_VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_py=$(find_existing_python 2>/dev/null); then
      link_python_into_libscript_home "$_existing_py"
      log_info "[REUSE] python ${PYTHON_VERSION} found at ${_existing_py}."
      exit 0
    fi

    # Fast native Python installation via uv python install before falling back to system/source
    if [ "$PYTHON_INSTALL_METHOD" = "libscript_native" ] || [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      if ! command -v uv >/dev/null 2>&1 && [ -x "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/uv/cli.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/uv/cli.sh" install latest >/dev/null 2>&1 || true
        if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/uv/env.sh" ]; then
          STACK=""
          SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/uv/env.sh"
          # shellcheck disable=SC1090,SC1091
          . "${SCRIPT_NAME}" || true
          unset SCRIPT_NAME || true
        fi
      fi
      if command -v uv >/dev/null 2>&1; then
        _req_py=$(printf '%s' "$PYTHON_VERSION" | cut -d. -f1,2)
        [ "$_req_py" = "latest" ] && _req_py="3.12"
        log_info "[CREATE] Installing Python ${_req_py} via uv..."
        if uv python install "$_req_py" >/dev/null 2>&1; then
          if _uv_py=$(find_existing_python 2>/dev/null); then
            link_python_into_libscript_home "$_uv_py"
            log_info "Installed Python ${PYTHON_VERSION} at ${_uv_py}."
            exit 0
          fi
        fi
      fi
    fi

    if [ "$PYTHON_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'python'
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
        elif command -v apk >/dev/null 2>&1; then
          libscript_depends 'build-base' 'openssl-dev' 'bzip2-dev' 'libffi-dev' 'zlib-dev' 'readline-dev' 'sqlite-dev' 'wget' 'curl' 'xz-dev' 'linux-headers'
        else
          libscript_depends 'wget' 'curl' 'xz' 'openssl' 'readline' 'sqlite3' 'gcc' 'make'
        fi
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/python/"*"${EXACT_VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
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
        
        if [ ! -f "${PY_DIR}/bin/python" ] && [ -f "${PY_DIR}/bin/python${PY_MINOR_VER}" ]; then
          ln -sf "python${PY_MINOR_VER}" "${PY_DIR}/bin/python"
        fi
        if [ ! -f "${PY_DIR}/bin/python3" ] && [ -f "${PY_DIR}/bin/python${PY_MINOR_VER}" ]; then
          ln -sf "python${PY_MINOR_VER}" "${PY_DIR}/bin/python3"
        fi
        
        if [ -x "${PY_DIR}/bin/python" ] && ! "${PY_DIR}/bin/python" -m pip --version >/dev/null 2>&1; then
           "${PY_DIR}/bin/python" -m ensurepip || true
        fi
        
        libscript_symlink_alias "python" "${PYTHON_VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias "python" "default" "${EXACT_VERSION}"
        libscript_symlink_alias "python" "latest" "${EXACT_VERSION}"
      fi

      if [ "${PYTHON_VENV-}" ]; then
        export VENV="${PYTHON_VENV}"
        if [ ! -f "${PYTHON_VENV}/bin/python" ]; then
          if ! type libscript_python_venv >/dev/null 2>&1; then
            . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
          fi
          libscript_python_venv "${PYTHON_VENV}" "${EXACT_VERSION}"
          
          _pip_cmd_opts=""
          if [ "${PIP_NO_INDEX:-0}" = "1" ]; then
            _pip_cmd_opts='--no-index'
            if [ -n "${PIP_FIND_LINKS:-}" ] && [ -d "${PIP_FIND_LINKS}" ]; then
              _pip_cmd_opts="${_pip_cmd_opts} --find-links ${PIP_FIND_LINKS}"
            fi
          fi

          "${PYTHON_VENV}/bin/python" -m pip install ${_pip_cmd_opts} -U pip setuptools wheel 2>/dev/null || true
          
          if [ -n "${ML_ACCELERATOR_BACKEND:-}" ] && [ "${PIP_NO_INDEX:-0}" != "1" ]; then
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
            "${PYTHON_VENV}/bin/python" -m pip install ${_pip_cmd_opts} -r 'requirements.txt'
          fi
          if [ -f 'setup.py' ] || [ -f 'setup.cfg' ] || [ -f 'pyproject.toml' ]; then
            "${PYTHON_VENV}/bin/python" -m pip install ${_pip_cmd_opts} -e .
          fi
        fi
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "python" "$ACTION" "$VERSION" "${PYTHON_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
