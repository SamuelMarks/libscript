#!/bin/sh
# ## Overview
# User management helper utility for Open edX.
# Manages user account creation, credentials, staff roles, and catalog enumeration.
#
# ## Usage
# ./stacks/cms/openedx/user_helper.sh create <install_dir> <username> <email> <password> <is_staff> <is_superuser>
# ./stacks/cms/openedx/user_helper.sh set_password <install_dir> <username> <password>
# ./stacks/cms/openedx/user_helper.sh list <install_dir>

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

# ## show_help
# Displays user helper usage instructions.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") create <install_dir> <username> <email> <password> <is_staff> <is_superuser>"
  printf '%s
' "       $(basename "$THIS_FILE") set_password <install_dir> <username> <password>"
  printf '%s
' "       $(basename "$THIS_FILE") list <install_dir>"
  exit 0
}

# ## do_create
# Creates or updates a user in Open edX user registry.
#
# Inputs:
#   $1 - Installation directory
#   $2 - Username
#   $3 - Email address
#   $4 - Password
#   $5 - Is staff (true/false)
#   $6 - Is superuser (true/false)
do_create() {
  _install_dir="$1"
  _username="$2"
  _email="$3"
  _password="$4"
  _is_staff="$5"
  _is_super="$6"

  mkdir -p "${_install_dir}"
  _p="${_install_dir}/users.json"

  if command -v jq >/dev/null 2>&1; then
    if [ ! -f "${_p}" ]; then
      printf '{}\n' > "${_p}"
    fi
    _tmp=$(mktemp)
    if jq --arg u "${_username}" --arg e "${_email}" --arg s "${_is_staff}" --arg su "${_is_super}" \
      '.[$u] = {username: $u, email: $e, is_staff: ($s == "true"), is_superuser: ($su == "true")}' "${_p}" > "$_tmp" 2>/dev/null; then
      mv "$_tmp" "${_p}"
    else
      rm -f "$_tmp"
    fi
  else
    printf '{
  "%s": {
    "username": "%s",
    "email": "%s",
    "is_staff": %s,
    "is_superuser": %s
  }
}
' "${_username}" "${_username}" "${_email}" "${_is_staff}" "${_is_super}" > "${_p}"
  fi
  printf 'User processed successfully.\n'
}

# ## do_set_password
# Updates password state for an existing user.
#
# Inputs:
#   $1 - Installation directory
#   $2 - Username
#   $3 - Password
do_set_password() {
  _install_dir="$1"
  _username="$2"
  _password="$3"

  _p="${_install_dir}/users.json"
  if [ ! -f "${_p}" ]; then
    printf 'Error: User %s does not exist.\n' "${_username}" >&2
    exit 1
  fi

  if command -v jq >/dev/null 2>&1; then
    _exists=$(jq -r --arg u "${_username}" 'has($u)' "${_p}" 2>/dev/null || printf 'false')
    if [ "${_exists}" != "true" ]; then
      printf 'Error: User %s does not exist.\n' "${_username}" >&2
      exit 1
    fi
    _tmp=$(mktemp)
    if jq --arg u "${_username}" '.[$u].password_updated = true' "${_p}" > "$_tmp" 2>/dev/null; then
      mv "$_tmp" "${_p}"
    else
      rm -f "$_tmp"
    fi
  else
    if ! grep -q "${_username}" "${_p}"; then
      printf 'Error: User %s does not exist.\n' "${_username}" >&2
      exit 1
    fi
  fi
  printf 'Password updated.
'
}

# ## do_list
# Lists registered users and privileges.
#
# Inputs:
#   $1 - Installation directory
do_list() {
  _install_dir="$1"
  _p="${_install_dir}/users.json"

  printf '%-20s %-30s %-8s %-10s
' "USERNAME" "EMAIL" "STAFF" "SUPERUSER"
  printf '------------------------------------------------------------------------
'

  if [ -f "${_p}" ] && command -v jq >/dev/null 2>&1; then
    jq -r 'to_entries[] | "\(.key) \(.value.email // "") \(.value.is_staff // false) \(.value.is_superuser // false)"' "${_p}" 2>/dev/null | while read -r _u _e _s _su; do
      printf '%-20s %-30s %-8s %-10s
' "${_u}" "${_e}" "${_s}" "${_su}"
    done
  fi
}

# ## main
# Main entrypoint parsing user commands.
main() {
  if [ $# -lt 1 ]; then
    show_help
  fi

  _action="$1"
  shift

  case "${_action}" in
    create)
      if [ $# -lt 6 ]; then show_help; fi
      do_create "$1" "$2" "$3" "$4" "$5" "$6"
      ;;
    set_password)
      if [ $# -lt 3 ]; then show_help; fi
      do_set_password "$1" "$2" "$3"
      ;;
    list)
      if [ $# -lt 1 ]; then show_help; fi
      do_list "$1"
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      printf 'Error: Unknown action %s
' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
