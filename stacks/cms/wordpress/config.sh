#!/bin/sh
# ## Overview
# Configuration inspection and mutation tool for WordPress 7.1.2.
# Reads, updates, and dumps wp-config.php constants and environment settings.
#
# ## Usage
#   ./config.sh <get|set|dump> [key] [value]

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
WP_CONFIG="${WWWROOT}/wp-config.php"

CMD="${1:-dump}"

if [ "$CMD" = "help" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ]; then
  cat << 'EOF_HELP'
WordPress Configuration Management

Usage:
  ./config.sh get <KEY>         Retrieve constant value from wp-config.php
  ./config.sh set <KEY> <VAL>   Set or append constant in wp-config.php
  ./config.sh dump              Dump non-secret constants
EOF_HELP
  exit 0
fi

if [ ! -f "$WP_CONFIG" ]; then
  printf '[ERROR] wp-config.php not found at %s
' "$WP_CONFIG" >&2
  exit 1
fi

case "$CMD" in
  get)
    shift
    if [ $# -lt 1 ]; then
      printf '[ERROR] Usage: %s get <CONSTANT_NAME>
' "$THIS_FILE" >&2
      exit 1
    fi
    KEY="$1"
    grep "define( *'${KEY}'" "$WP_CONFIG" 2>/dev/null | sed -E "s/.*'${KEY}' *, *(.*)\);/\1/" | tr -d "'" || true
    ;;
  set)
    shift
    if [ $# -lt 2 ]; then
      printf '[ERROR] Usage: %s set <CONSTANT_NAME> <VALUE>
' "$THIS_FILE" >&2
      exit 1
    fi
    KEY="$1"
    VAL="$2"
    if grep -q "define( *'${KEY}'" "$WP_CONFIG" 2>/dev/null; then
      sed -i.bak "s|define( *'${KEY}'.*|define( '${KEY}', '${VAL}' );|" "$WP_CONFIG"
      rm -f "${WP_CONFIG}.bak"
    else
      # Append before wp-settings.php
      TMP_CFG=$(mktemp)
      awk -v k="$KEY" -v v="$VAL" '
        /require_once.*wp-settings\.php/ {
          print "define( "" k "", "" v "" );
"
        }
        { print }
      ' "$WP_CONFIG" > "$TMP_CFG"
      cp "$TMP_CFG" "$WP_CONFIG"
      rm -f "$TMP_CFG"
    fi
    printf '[OK] Config key %s updated.
' "$KEY"
    ;;
  dump)
    cat << 'EOF_HEADER'
=== WordPress 7.1.2 wp-config.php Constants ===
EOF_HEADER
    grep "define( *'" "$WP_CONFIG" 2>/dev/null | grep -v 'KEY\|SALT' | sed -E "s/define\( *'([^']*)' *, *'([^']*)'.*/\1 = \2/" || true
    ;;
  help|--help|-h)
    cat << 'EOF_HELP'
WordPress Configuration Management

Usage:
  ./config.sh get <KEY>         Retrieve constant value from wp-config.php
  ./config.sh set <KEY> <VAL>   Set or append constant in wp-config.php
  ./config.sh dump              Dump non-secret constants
EOF_HELP
    exit 0
    ;;
  *)
    printf '[ERROR] Unknown command: %s
' "$CMD" >&2
    exit 1
    ;;
esac
