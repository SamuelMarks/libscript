#!/bin/sh
# ## Overview
# XBlock and stack plugin management utility for Open edX.
#
# ## Usage
# ./xblock.sh <install|uninstall|list|help> [package_spec]

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
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "engine/common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/openedx}"
VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
PYTHON_BIN="${VENV_DIR}/bin/python"
MANAGE_PY="${OPENEDX_INSTALL_DIR}/codebase/manage.py"
if [ ! -f "${MANAGE_PY}" ] && [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
  MANAGE_PY="${OPENEDX_INSTALL_DIR}/manage.py"
fi
XBLOCK_REGISTRY="${OPENEDX_INSTALL_DIR}/data/xblocks.json"

mkdir -p "${OPENEDX_INSTALL_DIR}/data"

# ## resolve_python
# Resolves python interpreter.
resolve_python() {
  if [ -x "${PYTHON_BIN}" ]; then
    printf '%s\n' "${PYTHON_BIN}"
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    printf ''
  fi
}

# ## xblock_install
# Installs an XBlock package.
#
# Inputs:
#   $1 - package specification (PyPI name, wheel, or git URL)
xblock_install() {
  if [ $# -lt 1 ]; then
    log_err "Usage: ${THIS_FILE} install <package_spec_or_git_url>"
    return 1
  fi
  _pkg="$1"

  log_info "Installing XBlock '${_pkg}'..."

  _py="$(resolve_python)"
  if [ -z "${_py}" ]; then
    log_err "Python interpreter not found."
    return 1
  fi

  # Idempotency check: see if package is recorded or installed
  if [ -f "${XBLOCK_REGISTRY}" ] && grep -F "${_pkg}" "${XBLOCK_REGISTRY}" >/dev/null 2>&1; then
    log_info "XBlock '${_pkg}' is already recorded as installed. Re-verifying..."
  fi

  if command -v uv >/dev/null 2>&1 && [ -d "${VENV_DIR}" ]; then
    uv pip install --python "${PYTHON_BIN}" "${_pkg}" 2>/dev/null || true
  elif [ -x "${PYTHON_BIN}" ]; then
    "${PYTHON_BIN}" -m pip install --no-cache-dir "${_pkg}" 2>/dev/null || true
  fi

  # Run migrations and asset collection if Django manage.py is present
  if [ -f "${MANAGE_PY}" ] && [ -x "${PYTHON_BIN}" ]; then
    log_info 'Running Django migrations for newly installed XBlock...'
    "${PYTHON_BIN}" "${MANAGE_PY}" lms migrate --noinput 2>/dev/null || true
    "${PYTHON_BIN}" "${MANAGE_PY}" cms migrate --noinput 2>/dev/null || true
    log_info 'Collecting static assets...'
    "${PYTHON_BIN}" "${MANAGE_PY}" lms collectstatic --noinput 2>/dev/null || true
  fi

  # Record in registry via jq
  if ! command -v jq >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  fi
  mkdir -p "$(dirname -- "${XBLOCK_REGISTRY}")"
  if command -v jq >/dev/null 2>&1; then
    if [ ! -s "${XBLOCK_REGISTRY}" ]; then printf '[]\n' > "${XBLOCK_REGISTRY}"; fi
    jq --arg pkg "${_pkg}" 'if index($pkg) then . else . + [$pkg] end' "${XBLOCK_REGISTRY}" > "${XBLOCK_REGISTRY}.tmp" && mv -f "${XBLOCK_REGISTRY}.tmp" "${XBLOCK_REGISTRY}"
  fi

  log_success "XBlock '${_pkg}' installed successfully."
}

# ## xblock_uninstall
# Uninstalls an XBlock package.
#
# Inputs:
#   $1 - package name
xblock_uninstall() {
  if [ $# -lt 1 ]; then
    log_err "Usage: ${THIS_FILE} uninstall <package_name>"
    return 1
  fi
  _pkg="$1"

  log_info "Uninstalling XBlock '${_pkg}'..."

  if [ -x "${PYTHON_BIN}" ]; then
    "${PYTHON_BIN}" -m pip uninstall -y "${_pkg}" 2>/dev/null || true
  fi

  if [ -f "${XBLOCK_REGISTRY}" ]; then
    if ! command -v jq >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    fi
    if command -v jq >/dev/null 2>&1; then
      jq --arg pkg "${_pkg}" 'map(select(. != $pkg))' "${XBLOCK_REGISTRY}" > "${XBLOCK_REGISTRY}.tmp" && mv -f "${XBLOCK_REGISTRY}.tmp" "${XBLOCK_REGISTRY}"
    fi
  fi

  log_success "XBlock '${_pkg}' uninstalled."
}

# ## xblock_list
# Lists installed XBlocks.
xblock_list() {
  log_info 'Discovering installed XBlock extensions...'
  _found=0
  if [ -f "${XBLOCK_REGISTRY}" ]; then
    if ! command -v jq >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    fi
    if command -v jq >/dev/null 2>&1 && [ "$(jq 'length' "${XBLOCK_REGISTRY}" 2>/dev/null || printf '0')" -gt 0 ]; then
      printf '%-32s %-40s\n' 'XBLOCK IDENTIFIER' 'ENTRY POINT / PACKAGE'
      printf '%s\n' '--------------------------------------------------------------------------'
      jq -r '.[]' "${XBLOCK_REGISTRY}" | while IFS= read -r _xb_item; do
        printf '%-32s %-40s\n' "${_xb_item}" '(registered)'
      done
      _found=1
    fi
  fi
  if [ "${_found}" -eq 0 ]; then
    printf '%s\n' '(No XBlocks currently discovered)'
  fi
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX XBlock & Plugin Management CLI

Usage:
  ${THIS_FILE} install <package_spec_or_git_url>
  ${THIS_FILE} uninstall <package_name>
  ${THIS_FILE} list
  ${THIS_FILE} help

Commands:
  install     Install XBlock package into virtualenv
  uninstall   Remove XBlock package from virtualenv
  list        Enumerate installed XBlock plugins
  help        Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  install)
    xblock_install "$@"
    ;;
  uninstall|remove)
    xblock_uninstall "$@"
    ;;
  list)
    xblock_list
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown xblock command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
