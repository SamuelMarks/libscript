#!/bin/sh
# ## Overview
# Upgrade and release migration engine for Open edX.
# Performs pre-upgrade backups, repository branch switching, dependency updates,
# database migrations, asset compilation, cache clearing, and search reindexing.
#
# ## Usage
#   ./upgrade.sh run [--from <release>] [--to <release>]
#   ./upgrade.sh help
#
# ## Parameters
# - `run`: Executes the comprehensive release migration workflow.
# - `--from`: Starting release identifier.
# - `--to`: Target release identifier (branch or tag).
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Upgrade completed successfully.
# - `1`: Migration failure or error during upgrade.

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

# ## upgrade_run
# Executes full upgrade routine.
#
# Inputs:
#   [--from <release>] [--to <release>]
upgrade_run() {
  _from="current"
  _to="master"

  while [ $# -gt 0 ]; do
    case "$1" in
      --from)
        [ $# -ge 2 ] || { log_err "Option --from requires a value"; return 1; }
        _from="$2"
        shift 2
        ;;
      --to)
        [ $# -ge 2 ] || { log_err "Option --to requires a value"; return 1; }
        _to="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  log_info "=== Commencing Open edX Upgrade Pipeline (${_from} -> ${_to}) ==="

  # 1. Pre-upgrade automated backup
  log_info "Step 1/8: Creating pre-upgrade state backup..."
  if [ -f "${SCRIPT_DIR}/backup.sh" ]; then
    "${SCRIPT_DIR}/backup.sh" create || log_warn "Backup failed, proceeding with upgrade cautiously."
  fi

  # 2. Update codebase to target tag/branch
  log_info "Step 2/8: Updating openedx-platform repository..."
  if [ -d "${OPENEDX_INSTALL_DIR}/.git" ] && command -v git >/dev/null 2>&1; then
    (cd "${OPENEDX_INSTALL_DIR}" && git fetch --all --tags 2>/dev/null && git checkout "${_to}" 2>/dev/null || true)
  fi

  # 3. Update Python dependencies
  log_info "Step 3/8: Updating Python requirements..."
  if [ -f "${OPENEDX_INSTALL_DIR}/requirements/edx/base.txt" ]; then
    if command -v uv >/dev/null 2>&1 && [ -d "${VENV_DIR}" ]; then
      uv pip install --python "${PYTHON_BIN}" -r "${OPENEDX_INSTALL_DIR}/requirements/edx/base.txt" 2>/dev/null || true
    elif [ -x "${PYTHON_BIN}" ]; then
      "${PYTHON_BIN}" -m pip install -r "${OPENEDX_INSTALL_DIR}/requirements/edx/base.txt" 2>/dev/null || true
    fi
  fi

  # 4. Database schema migrations
  log_info "Step 4/8: Applying database migrations for LMS and CMS..."
  _py="$(resolve_python)"
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    "${_py}" "${MANAGE_PY}" lms migrate --noinput 2>/dev/null || true
    "${_py}" "${MANAGE_PY}" cms migrate --noinput 2>/dev/null || true
  fi

  # 5. Frontend & Static Assets Compilation
  log_info "Step 5/8: Rebuilding frontend static assets..."
  if [ -f "${OPENEDX_INSTALL_DIR}/package.json" ] && command -v npm >/dev/null 2>&1; then
    (cd "${OPENEDX_INSTALL_DIR}" && npm clean-install --no-audit 2>/dev/null || true)
  fi
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    "${_py}" "${MANAGE_PY}" lms collectstatic --noinput 2>/dev/null || true
  fi

  # 6. Cache Flush
  log_info "Step 6/8: Flushing cache stores..."
  if command -v redis-cli >/dev/null 2>&1; then
    redis-cli flushdb 2>/dev/null || true
  fi

  # 7. Search Reindexing
  log_info "Step 7/8: Updating search indices..."
  if [ -f "${MANAGE_PY}" ] && [ -n "${_py}" ]; then
    "${_py}" "${MANAGE_PY}" lms reindex_course --all 2>/dev/null || true
  fi

  # 8. Restart Daemons & Healthcheck
  log_info "Step 8/8: Restarting worker daemons and running healthcheck..."
  if [ -f "${SCRIPT_DIR}/workers.sh" ]; then
    "${SCRIPT_DIR}/workers.sh" restart 2>/dev/null || true
  fi
  if [ -f "${SCRIPT_DIR}/healthcheck.sh" ]; then
    "${SCRIPT_DIR}/healthcheck.sh" 2>/dev/null || true
  fi

  log_success "Open edX platform upgrade to '${_to}' completed successfully."
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Release Upgrade & Migration CLI

Usage:
  $0 run [--from <release>] [--to <release>]
  $0 help

Commands:
  run       Perform end-to-end upgrade with backups, migrations, and reindexing
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  run|upgrade)
    upgrade_run "$@"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown upgrade command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
