#!/bin/sh
# ## Overview
# Snapshot backup module for WordPress 7.1.2.
# Archives the MySQL database dump, wp-content uploads, themes, plugins, and wp-config.php
# into a compressed timestamped archive.
#
# ## Usage
#   ./backup.sh [create] [--out <output_path>]

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
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/wordpress/backups"
OUT_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    create)
      shift
      ;;
    --out|-o)
      if [ -d "$2" ]; then
        OUT_DIR="$2"
      else
        OUT_FILE="$2"
      fi
      shift 2
      ;;
    help|--help|-h)
      cat << 'EOF_HELP'
WordPress Backup Utility

Usage:
  ./backup.sh [create] [--out <path_or_dir>]
EOF_HELP
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$OUT_DIR"
if [ -z "$OUT_FILE" ]; then
  OUT_FILE="${OUT_DIR}/wordpress_backup_${TIMESTAMP}.tar.gz"
fi

TMP_DIR=$(mktemp -d)
printf '[INFO] Initiating WordPress snapshot backup...
'

# 1. Export MySQL Database
printf '[INFO] Dumping WordPress database...
'
if [ -x "$DBSHELL" ]; then
  "$DBSHELL" export "${TMP_DIR}/database.sql"
fi

# 2. Copy wp-content and wp-config.php
if [ -d "${WWWROOT}/wp-content" ]; then
  cp -r "${WWWROOT}/wp-content" "${TMP_DIR}/wp-content"
fi
if [ -f "${WWWROOT}/wp-config.php" ]; then
  cp "${WWWROOT}/wp-config.php" "${TMP_DIR}/wp-config.php"
fi

# 3. Create compressed tarball
printf '[INFO] Archiving snapshot payload into %s...
' "$OUT_FILE"
tar -czf "$OUT_FILE" -C "$TMP_DIR" .
rm -rf "$TMP_DIR"

printf '[OK] WordPress snapshot backup created successfully: %s
' "$OUT_FILE"
exit 0
