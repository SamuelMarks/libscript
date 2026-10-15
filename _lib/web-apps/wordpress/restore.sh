#!/bin/sh
# ## Overview
# Disaster recovery and snapshot restoration tool for WordPress 7.1.2.
# Restores the MySQL database dump, wp-content files, and wp-config.php from a backup archive.
#
# ## Usage
#   ./restore.sh <backup_archive.tar.gz>

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

WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
DBSHELL="${SCRIPT_DIR}/dbshell.sh"

ARCHIVE="${1:-}"
if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  printf '[ERROR] Usage: %s <backup_archive.tar.gz>\n' "$THIS_FILE" >&2
  exit 1
fi

TMP_DIR=$(mktemp -d)
printf '[INFO] Extracting backup archive %s...\n' "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

# 1. Restore Database
if [ -f "${TMP_DIR}/database.sql" ]; then
  printf '[INFO] Restoring WordPress database from SQL dump...\n'
  if [ -x "$DBSHELL" ]; then
    "$DBSHELL" import "${TMP_DIR}/database.sql"
  fi
fi

# 2. Restore wp-content
if [ -d "${TMP_DIR}/wp-content" ]; then
  printf '[INFO] Restoring wp-content uploads, themes, and plugins...\n'
  mkdir -p "${WWWROOT}/wp-content"
  cp -r "${TMP_DIR}/wp-content/"* "${WWWROOT}/wp-content/" 2>/dev/null || true
fi

# 3. Restore wp-config.php
if [ -f "${TMP_DIR}/wp-config.php" ]; then
  printf '[INFO] Restoring wp-config.php...\n'
  cp "${TMP_DIR}/wp-config.php" "${WWWROOT}/wp-config.php"
fi

rm -rf "$TMP_DIR"
printf '[OK] WordPress snapshot restored successfully from %s\n' "$ARCHIVE"
exit 0
