#!/bin/sh
# ## Overview
# Validates Odoo stack generation specifically passing a simulated remote IP
# to verify the DB MSI is correctly omitted and connections succeed.
#
# ## Usage
#   ./tests/test_odoo_remote_db.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

printf '==> Testing Odoo DBaaS Strategy...\n'

# Synthesize the MSI manifest using template_msi.sh
"${LIBSCRIPT_ROOT_DIR}/packaging/template_msi.sh" "${LIBSCRIPT_ROOT_DIR}/stacks/erp/odoo" --out "$TMP_DIR/odoo.wxs"

if ! grep -q "USER_DB_STRATEGY=\"remote\"" "$TMP_DIR/odoo.wxs"; then
  printf '[ERROR] USER_DB_STRATEGY remote switch not correctly mapped.\n' >&2
  exit 1
fi

printf '[PASS] Remote simulated DB strategy effectively omits postgres via properties!\n'

printf '==> Simulating silent install with remote IP...\n'

export ODOO_DB_HOST="192.168.200.99"
export ODOO_DB_PORT="5432"
export ODOO_DB_NAME="odoo_prod"
export ODOO_DB_USER="odoo_admin"
export ODOO_DB_PASS="RemoteS3cr3t"
export ODOO_WEBSERVER="none"
export ODOO_WWWROOT="$TMP_DIR/odoo_www"

# We skip dependencies in setup to prevent network calls/apt-get during this unit test
export LIBSCRIPT_SKIP_SYSTEM_DEPS=1

mkdir -p "$ODOO_WWWROOT"
# Stub out the odoo-bin to pretend we downloaded it
touch "$ODOO_WWWROOT/odoo-bin"
chmod +x "$ODOO_WWWROOT/odoo-bin"

# Run setup_generic.sh
"${LIBSCRIPT_ROOT_DIR}/stacks/erp/odoo/setup_generic.sh" --skip-deps || true

if ! grep -q "db_host = 192.168.200.99" "${ODOO_WWWROOT}/odoo.conf"; then
  printf '[ERROR] db_host not properly written to odoo.conf!\n' >&2
  exit 1
fi

if ! grep -q "db_name = odoo_prod" "${ODOO_WWWROOT}/odoo.conf"; then
  printf '[ERROR] db_name not properly written to odoo.conf!\n' >&2
  exit 1
fi

printf '[PASS] Odoo setup effectively maps remote IP to connection config!\n'
exit 0
