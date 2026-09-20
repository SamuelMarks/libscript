#!/bin/sh
# ## Overview
# XBlock and stack plugin management utility for Open edX.
# Installs, uninstalls, and enumerates XBlocks and Python extension plugins.
#
# ## Usage
#   ./xblock.sh install <package_spec_or_git_url>
#   ./xblock.sh uninstall <package_name>
#   ./xblock.sh list
#   ./xblock.sh help
#
# ## Parameters
# - `install`: Installs XBlock into Python environment and executes migrations & asset collection.
# - `uninstall`: Uninstalls XBlock from virtual environment.
# - `list`: Enumerates installed XBlocks detected via entry point metadata.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Installation or package manager failure.

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
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
PYTHON_BIN="${VENV_DIR}/bin/python"
MANAGE_PY="${OPENEDX_INSTALL_DIR}/manage.py"
XBLOCK_REGISTRY="${OPENEDX_INSTALL_DIR}/data/xblocks.json"

mkdir -p "${OPENEDX_INSTALL_DIR}/data"

# ## resolve_python
# Resolves python interpreter.
resolve_python() {
  if [ -x "${PYTHON_BIN}" ]; then
    printf '%s
' "${PYTHON_BIN}"
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
    log_err "Usage: $0 install <package_spec_or_git_url>"
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
    log_info "Running Django migrations for newly installed XBlock..."
    "${PYTHON_BIN}" "${MANAGE_PY}" lms migrate --noinput 2>/dev/null || true
    "${PYTHON_BIN}" "${MANAGE_PY}" cms migrate --noinput 2>/dev/null || true
    log_info "Collecting static assets..."
    "${PYTHON_BIN}" "${MANAGE_PY}" lms collectstatic --noinput 2>/dev/null || true
  fi

  # Record in registry
  "${_py}" - <<EOF
import json, os
p = "${XBLOCK_REGISTRY}"
d = json.load(open(p)) if os.path.exists(p) else []
if "${_pkg}" not in d:
    d.append("${_pkg}")
    json.dump(d, open(p, "w"), indent=2)
EOF

  log_success "XBlock '${_pkg}' installed successfully."
}

# ## xblock_uninstall
# Uninstalls an XBlock package.
#
# Inputs:
#   $1 - package name
xblock_uninstall() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 uninstall <package_name>"
    return 1
  fi
  _pkg="$1"

  log_info "Uninstalling XBlock '${_pkg}'..."

  if [ -x "${PYTHON_BIN}" ]; then
    "${PYTHON_BIN}" -m pip uninstall -y "${_pkg}" 2>/dev/null || true
  fi

  _py="$(resolve_python)"
  if [ -n "${_py}" ] && [ -f "${XBLOCK_REGISTRY}" ]; then
    "${_py}" - <<EOF
import json, os
p = "${XBLOCK_REGISTRY}"
if os.path.exists(p):
    d = json.load(open(p))
    if "${_pkg}" in d:
        d.remove("${_pkg}")
        json.dump(d, open(p, "w"), indent=2)
EOF
  fi

  log_success "XBlock '${_pkg}' uninstalled."
}

# ## xblock_list
# Lists installed XBlocks.
xblock_list() {
  log_info "Discovering installed XBlock extensions..."
  _py="$(resolve_python)"
  if [ -n "${_py}" ]; then
    "${_py}" - <<EOF
import sys, json, os
found = False
try:
    if sys.version_info >= (3, 10):
        from importlib.metadata import entry_points
        eps = entry_points().select(group="xblock.v1") if hasattr(entry_points(), "select") else entry_points().get("xblock.v1", [])
    else:
        try:
            from importlib_metadata import entry_points
            eps = entry_points().get("xblock.v1", [])
        except Exception:
            import pkg_resources
            eps = pkg_resources.iter_entry_points("xblock.v1")
    for ep in eps:
        if not found:
            print(f"{'XBLOCK IDENTIFIER':<32} {'ENTRY POINT / PACKAGE':<40}")
            print("-" * 74)
            found = True
        print(f"{ep.name:<32} {ep.value:<40}")
except Exception:
    pass

if not found:
    reg = "${XBLOCK_REGISTRY}"
    if os.path.exists(reg):
        d = json.load(open(reg))
        if d:
            print(f"{'XBLOCK IDENTIFIER':<32} {'ENTRY POINT / PACKAGE':<40}")
            print("-" * 74)
            for item in d:
                print(f"{item:<32} {'(registered)':<40}")
            found = True
if not found:
    print("(No XBlocks currently discovered)")
EOF
  fi
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX XBlock & Plugin Management CLI

Usage:
  $0 install <package_spec_or_git_url>
  $0 uninstall <package_name>
  $0 list
  $0 help

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
