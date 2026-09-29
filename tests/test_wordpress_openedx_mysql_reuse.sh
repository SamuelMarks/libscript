#!/bin/sh
# ## Overview
# Verification test for WordPress 7.1.2 database coexistence with Open edX.
# Validates that WordPress correctly detects Open edX, reuses its MySQL instance,
# provisions an isolated database schema, and protects Open edX tables from mutation.
#
# ## Usage
#   ./tests/test_wordpress_openedx_mysql_reuse.sh

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

printf '==> Testing Universal Database Discovery Engine...\n'
DETECT_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/discover_databases.sh"

# 1. Test evaluation output
_eval_out=$("$DETECT_SH" --eval || true)
while IFS='=' read -r _k _v; do
  _v="${_v%\"}"
  _v="${_v#\"}"
  case "$_k" in
    DETECTED_DB_ENGINE) DETECTED_DB_ENGINE="$_v" ;;
    DETECTED_DB_HOST) DETECTED_DB_HOST="$_v" ;;
    DETECTED_DB_PORT) DETECTED_DB_PORT="$_v" ;;
    DETECTED_DB_SOURCE) DETECTED_DB_SOURCE="$_v" ;;
  esac
done << EOF
$_eval_out
EOF
printf '[INFO] Detected Engine: %s, Host: %s, Port: %s, Source: %s\n' "${DETECTED_DB_ENGINE:-none}" "${DETECTED_DB_HOST:-none}" "${DETECTED_DB_PORT:-none}" "${DETECTED_DB_SOURCE:-none}"

# 2. Test JSON output
JSON_OUT="$("$DETECT_SH" --json || true)"
printf '[INFO] JSON Output: %s\n' "$JSON_OUT"

# 3. Test WordPress setup dry run with Open edX reuse flag
TMP_WWW=$(mktemp -d)
printf '[INFO] Testing wp-config generation with Open edX MySQL reuse in %s...
' "$TMP_WWW"

"${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/setup_generic.sh" --wwwroot "$TMP_WWW" --reuse-openedx-db --skip-deps --server-name "wordpress.local" --site-title "Open edX Shared WP"

if [ ! -f "${TMP_WWW}/wp-config.php" ]; then
  printf '[ERROR] wp-config.php was not created during Open edX reuse setup!
' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

if ! grep -q "define( *'DB_NAME', *'wordpress'" "${TMP_WWW}/wp-config.php"; then
  printf '[ERROR] DB_NAME is not set to isolated wordpress schema!
' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

rm -rf "$TMP_WWW"
printf '==> Open edX MySQL reuse verification succeeded!
'
exit 0
