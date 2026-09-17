#!/bin/sh
# ## Overview
# Generic setup module for nodeenv.
# 
# ## Usage
# Execute this script to perform generic initialization steps for nodeenv.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
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

NODEENV_INSTALL_METHOD="${NODEENV_INSTALL_METHOD:-system}"
NODEENV_INSTALL_METHOD="$(LIBSCRIPT_DEFAULT_INSTALL_METHOD="$NODEENV_INSTALL_METHOD" libscript_resolve_install_method "NODEENV")"
ACTION="${ACTION:-install}"
VERSION="${NODEENV_VERSION:-latest}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ]; then
    EXACT_VERSION="1.9.1"
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if [ "$NODEENV_INSTALL_METHOD" = "libscript_native" ]; then
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/nodeenv/" 2>/dev/null || true
    else
      command -v nodeenv >/dev/null 2>&1 && nodeenv --version || printf 'nodeenv not found
'
    fi
    exit 0
    ;;
  ls-remote)
    printf '1.9.0
1.9.1
'
    exit 0
    ;;
  install)
    resolve_exact_version
    if [ "$NODEENV_INSTALL_METHOD" = "libscript_native" ]; then
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/nodeenv/${EXACT_VERSION}"
      if [ -f "${TARGET_DIR}/bin/nodeenv" ]; then
        log_info "nodeenv ${EXACT_VERSION} is already installed in ${TARGET_DIR}."
      else
        log_info "Installing nodeenv ${EXACT_VERSION} via isolated Python venv..."
        mkdir -p "${TARGET_DIR}"
        if command -v uv >/dev/null 2>&1; then
          uv venv "${TARGET_DIR}"
          if [ "${VERSION}" = "latest" ]; then
            uv pip install --python "${TARGET_DIR}/bin/python" nodeenv
          else
            uv pip install --python "${TARGET_DIR}/bin/python" "nodeenv==${EXACT_VERSION}"
          fi
        else
          python3 -m venv "${TARGET_DIR}"
          if [ "${VERSION}" = "latest" ]; then
            "${TARGET_DIR}/bin/python" -m pip install --no-cache-dir nodeenv
          else
            "${TARGET_DIR}/bin/python" -m pip install --no-cache-dir "nodeenv==${EXACT_VERSION}"
          fi
        fi
      fi
      libscript_symlink_alias "nodeenv" "$VERSION" "${EXACT_VERSION}"
    else
      # System / pip / uv install
      if command -v nodeenv >/dev/null 2>&1; then
        log_info "nodeenv is already installed on the system: $(nodeenv --version 2>/dev/null || true)"
      elif command -v uv >/dev/null 2>&1; then
        log_info "Installing nodeenv via uv pip..."
        if [ "${VERSION}" = "latest" ]; then
          uv tool install nodeenv 2>/dev/null || uv pip install nodeenv
        else
          uv tool install "nodeenv==${EXACT_VERSION}" 2>/dev/null || uv pip install "nodeenv==${EXACT_VERSION}"
        fi
      elif command -v pipx >/dev/null 2>&1; then
        log_info "Installing nodeenv via pipx..."
        pipx install "nodeenv==${EXACT_VERSION}" 2>/dev/null || pipx install nodeenv
      elif command -v pip3 >/dev/null 2>&1; then
        log_info "Installing nodeenv via pip3..."
        pip3 install --user "nodeenv==${EXACT_VERSION}" 2>/dev/null || pip3 install --user nodeenv
      elif command -v pip >/dev/null 2>&1; then
        log_info "Installing nodeenv via pip..."
        pip install --user "nodeenv==${EXACT_VERSION}" 2>/dev/null || pip install --user nodeenv
      else
        log_info "Python package manager required for nodeenv. Installing python..."
        libscript_depends "python"
        pip3 install --user nodeenv || true
      fi
    fi
    ;;
  uninstall)
    resolve_exact_version
    if [ "$NODEENV_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Uninstalling nodeenv ${EXACT_VERSION}..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/nodeenv/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/nodeenv/${VERSION}"
    else
      command -v uv >/dev/null 2>&1 && uv tool uninstall nodeenv 2>/dev/null || true
      command -v pipx >/dev/null 2>&1 && pipx uninstall nodeenv 2>/dev/null || true
      command -v pip3 >/dev/null 2>&1 && pip3 uninstall -y nodeenv 2>/dev/null || true
    fi
    exit 0
    ;;
  test)
    command -v nodeenv >/dev/null 2>&1 && nodeenv --version
    exit 0
    ;;
esac
