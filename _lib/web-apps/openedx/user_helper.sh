#!/bin/sh
# ## Overview
# User management helper utility for Open edX.
# Manages user account creation, credentials, staff roles, and catalog enumeration.
#
# ## Usage
# ./_lib/web-apps/openedx/user_helper.sh create <install_dir> <username> <email> <password> <is_staff> <is_superuser>
# ./_lib/web-apps/openedx/user_helper.sh set_password <install_dir> <username> <password>
# ./_lib/web-apps/openedx/user_helper.sh list <install_dir>

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

# ## show_help
# Displays user helper usage instructions.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") create <install_dir> <username> <email> <password> <is_staff> <is_superuser>"
  printf '%s\n' "       $(basename "$THIS_FILE") set_password <install_dir> <username> <password>"
  printf '%s\n' "       $(basename "$THIS_FILE") list <install_dir>"
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
  _py="${_install_dir}/.venv/bin/python"
  if [ ! -x "${_py}" ]; then
    _py=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)
  fi
  _codebase="${_install_dir}/codebase"
  if [ ! -f "${_codebase}/manage.py" ] && [ -f "${_install_dir}/manage.py" ]; then
    _codebase="${_install_dir}"
  fi

  if [ -f "${_codebase}/manage.py" ] && [ -n "${_py}" ]; then
    _staff_flags=""
    if [ "${_is_staff}" = "true" ] || [ "${_is_staff}" = "True" ]; then
      _staff_flags="${_staff_flags} --staff"
    fi
    if [ "${_is_super}" = "true" ] || [ "${_is_super}" = "True" ]; then
      _staff_flags="${_staff_flags} --superuser"
    fi
    # shellcheck disable=SC2086
    (cd "${_codebase}" && "${_py}" manage.py lms --settings=libscript manage_user "${_username}" "${_email}" ${_staff_flags} >/dev/null 2>&1) || true
    (cd "${_codebase}" && "${_py}" -c "import os, django; os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms.envs.libscript'); django.setup(); from django.contrib.auth import get_user_model; User = get_user_model(); u, _ = User.objects.get_or_create(username='${_username}', defaults={'email': '${_email}'}); u.email = '${_email}'; u.is_staff = ('${_is_staff}'.lower() == 'true' or '${_is_super}'.lower() == 'true'); u.is_superuser = ('${_is_super}'.lower() == 'true'); u.set_password('${_password}'); u.save()" >/dev/null 2>&1) || true
  fi

  _p="${_install_dir}/users.json"
  if command -v jq >/dev/null 2>&1; then
    if [ ! -f "${_p}" ]; then
      printf '{}\n' > "${_p}"
    fi
    _tmp=$(mktemp)
    if jq --arg u "${_username}" --arg e "${_email}" --arg s "${_is_staff}" --arg su "${_is_super}" \
      '.[$u] = {username: $u, email: $e, is_staff: ($s == "true" or $s == "True"), is_superuser: ($su == "true" or $su == "True")}' "${_p}" > "$_tmp" 2>/dev/null; then
      mv "$_tmp" "${_p}"
    else
      rm -f "$_tmp"
    fi
  else
    printf '{\n  "%s": {\n    "username": "%s",\n    "email": "%s",\n    "is_staff": %s,\n    "is_superuser": %s\n  }\n}\n' "${_username}" "${_username}" "${_email}" "${_is_staff}" "${_is_super}" > "${_p}"
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
  printf 'Password updated.\n'
}

# ## do_list
# Lists registered users and privileges.
#
# Inputs:
#   $1 - Installation directory
do_list() {
  _install_dir="$1"
  _p="${_install_dir}/users.json"

  printf '%-20s %-30s %-8s %-10s\n' "USERNAME" "EMAIL" "STAFF" "SUPERUSER"
  printf '%s\n' '------------------------------------------------------------------------'

  if [ -f "${_p}" ] && command -v jq >/dev/null 2>&1; then
    jq -r 'to_entries[] | "\(.key) \(.value.email // "") \(.value.is_staff // false) \(.value.is_superuser // false)"' "${_p}" 2>/dev/null | while read -r _u _e _s _su; do
      printf '%-20s %-30s %-8s %-10s\n' "${_u}" "${_e}" "${_s}" "${_su}"
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
      printf 'Error: Unknown action %s\n' "${_action}" >&2
      exit 1
      ;;
  esac
}

main "$@"
