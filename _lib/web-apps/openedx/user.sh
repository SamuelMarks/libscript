#!/bin/sh
# ## Overview
# User management utility for Open edX.
# Provides interactive and scriptable administration for Django users (create, set_password, list).
#
# ## Usage
#   ./user.sh create <username> <email> [--password <password>] [--staff] [--superuser]
#   ./user.sh set_password <username> <password>
#   ./user.sh list
#
# ## Parameters
# - `create`: Creates or updates an Open edX user account idempotently.
# - `set_password`: Updates the password for an existing user account.
# - `list`: Lists active staff and superuser accounts.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Invalid arguments, missing dependencies, or command failure.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

if [ -f "${DIR}/env.sh" ]; then
  SCRIPT_NAME="${DIR}/env.sh"
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
USER_HELPER="${SCRIPT_DIR}/user_helper.sh"

# ## user_create
# Creates or updates an Open edX user account idempotently via user_helper.sh.
#
# Inputs:
#   $1 - username
#   $2 - email
#   Additional options:
#     --password <password>
#     --staff
#     --superuser
user_create() {
  if [ $# -lt 2 ]; then
    log_err "Usage: $0 create <username> <email> [--password <password>] [--staff] [--superuser]"
    return 1
  fi

  _username="$1"
  _email="$2"
  shift 2

  _password=""
  _is_staff="False"
  _is_superuser="False"

  while [ $# -gt 0 ]; do
    case "$1" in
      --password)
        [ $# -ge 2 ] || { log_err "Option --password requires a value"; return 1; }
        _password="$2"
        shift 2
        ;;
      --staff)
        _is_staff="True"
        shift
        ;;
      --superuser)
        _is_staff="True"
        _is_superuser="True"
        shift
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  if [ -z "${_password}" ]; then
    if [ -t 0 ]; then
      printf "Enter password for user '%s': " "${_username}"
      stty -echo 2>/dev/null || true
      read -r _password
      stty echo 2>/dev/null || true
      printf '\n'
    else
      log_err "Password must be provided via --password when running non-interactively."
      return 1
    fi
  fi

  log_info "Creating or updating user '${_username}' (${_email})..."
  "${USER_HELPER}" create "${OPENEDX_INSTALL_DIR}" "${_username}" "${_email}" "${_password}" "${_is_staff}" "${_is_superuser}"
  log_success "User '${_username}' processed successfully."
}

# ## user_set_password
# Updates password for an existing Open edX user via user_helper.sh.
#
# Inputs:
#   $1 - username
#   $2 - password
user_set_password() {
  if [ $# -lt 2 ]; then
    log_err "Usage: $0 set_password <username> <password>"
    return 1
  fi
  _username="$1"
  _password="$2"

  log_info "Updating password for user '${_username}'..."
  "${USER_HELPER}" set_password "${OPENEDX_INSTALL_DIR}" "${_username}" "${_password}"
  log_success "Password updated for '${_username}'."
}

# ## user_list
# Lists active staff and superuser accounts via user_helper.sh.
user_list() {
  log_info "Listing Open edX staff and superuser accounts..."
  "${USER_HELPER}" list "${OPENEDX_INSTALL_DIR}"
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX User Management CLI

Usage:
  $0 create <username> <email> [--password <password>] [--staff] [--superuser]
  $0 set_password <username> <password>
  $0 list
  $0 help

Commands:
  create        Create or update a user account idempotently
  set_password  Update user password
  list          List all registered users and roles
  help          Show this help message
EOF
}

# Router
COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  create)
    user_create "$@"
    ;;
  set_password|set-password)
    user_set_password "$@"
    ;;
  list)
    user_list
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
