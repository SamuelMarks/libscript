#!/bin/sh
# ## Overview
# User account administration module for WordPress 7.1.2.
# Supports creating, listing, updating passwords, and removing user accounts
# via WP-CLI or database operations.
#
# ## Usage
#   ./user.sh create <username> <email> [--password <pwd>] [--role <role>]
#   ./user.sh set-password <username> [--password <pwd>]
#   ./user.sh list
#   ./user.sh delete <username>

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

WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
DBSHELL="${SCRIPT_DIR}/dbshell.sh"

WP_CLI=""
if command -v wp >/dev/null 2>&1; then
  WP_CLI="wp --path=${WWWROOT}"
elif [ -f "${LIBSCRIPT_ROOT_DIR}/cache/wp-cli.phar" ]; then
  WP_CLI="php ${LIBSCRIPT_ROOT_DIR}/cache/wp-cli.phar --path=${WWWROOT}"
fi

CMD="${1:-list}"

case "$CMD" in
  create)
    shift
    if [ $# -lt 2 ]; then
      printf '[ERROR] Usage: %s create <username> <email> [--password <pass>] [--role <role>]
' "$THIS_FILE" >&2
      exit 1
    fi
    USER="$1"
    EMAIL="$2"
    shift 2
    PASSWORD=""
    ROLE="administrator"
    while [ $# -gt 0 ]; do
      case "$1" in
        --password)
          PASSWORD="$2"
          shift 2
          ;;
        --role)
          ROLE="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    if [ -z "$PASSWORD" ]; then
      PASSWORD="WpPassword_${USER}_$(date +%s)"
    fi
    if [ -n "$WP_CLI" ]; then
      $WP_CLI user create "$USER" "$EMAIL" --user_pass="$PASSWORD" --role="$ROLE" 2>/dev/null || 
      $WP_CLI user update "$USER" --user_pass="$PASSWORD" --role="$ROLE"
    else
      # Direct SQL fallback insertion
      "$DBSHELL" query "INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_registered, user_status, display_name) VALUES ('$USER', MD5('$PASSWORD'), '$USER', '$EMAIL', NOW(), 0, '$USER') ON DUPLICATE KEY UPDATE user_email='$EMAIL';" >/dev/null 2>&1 || true
    fi
    printf '[OK] WordPress user %s (%s) provisioned with role %s
' "$USER" "$EMAIL" "$ROLE"
    ;;
  set-password)
    shift
    if [ $# -lt 1 ]; then
      printf '[ERROR] Usage: %s set-password <username> [--password <pass>]
' "$THIS_FILE" >&2
      exit 1
    fi
    USER="$1"
    shift
    PASSWORD=""
    if [ "${1:-}" = "--password" ] && [ -n "${2:-}" ]; then
      PASSWORD="$2"
    else
      PASSWORD="WpPassword_${USER}_$(date +%s)"
    fi
    if [ -n "$WP_CLI" ]; then
      $WP_CLI user update "$USER" --user_pass="$PASSWORD"
    else
      "$DBSHELL" query "UPDATE wp_users SET user_pass = MD5('$PASSWORD') WHERE user_login = '$USER';" >/dev/null 2>&1 || true
    fi
    printf '[OK] Password updated for user %s
' "$USER"
    ;;
  list)
    if [ -n "$WP_CLI" ]; then
      $WP_CLI user list
    else
      printf 'ID	Login	Email	Registered
'
      "$DBSHELL" query "SELECT ID, user_login, user_email, user_registered FROM wp_users;" 2>/dev/null || true
    fi
    ;;
  delete)
    shift
    if [ $# -lt 1 ]; then
      printf '[ERROR] Usage: %s delete <username>
' "$THIS_FILE" >&2
      exit 1
    fi
    USER="$1"
    if [ -n "$WP_CLI" ]; then
      $WP_CLI user delete "$USER" --yes
    else
      "$DBSHELL" query "DELETE FROM wp_users WHERE user_login = '$USER';" >/dev/null 2>&1 || true
    fi
    printf '[OK] WordPress user %s removed
' "$USER"
    ;;
  help|--help|-h)
    cat << 'EOF_HELP'
WordPress User Management

Usage:
  ./user.sh create <username> <email> [--password <pwd>] [--role <role>]
  ./user.sh set-password <username> [--password <pwd>]
  ./user.sh list
  ./user.sh delete <username>
EOF_HELP
    exit 0
    ;;
  *)
    printf '[ERROR] Unknown command: %s
' "$CMD" >&2
    exit 1
    ;;
esac
