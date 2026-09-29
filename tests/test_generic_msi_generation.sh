#!/bin/sh
# ## Overview
# Verification test suite for universal declarative WiX XML manifest and MSI synthesis.
#
# ## Usage
#   ./tests/test_generic_msi_generation.sh

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

TEMPLATE_SH="${LIBSCRIPT_ROOT_DIR}/packaging/template_msi.sh"

printf '==> Running Declarative MSI Manifest Synthesis Verification Tests...
'

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/msi_gen_test_XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# 1. Test Open edX WiX generation
printf '[TEST 1] Synthesizing WiX manifest for Open edX...
'
"$TEMPLATE_SH" "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx" --out "$TMP_DIR/openedx.wxs"
grep -q "Open edX Platform" "$TMP_DIR/openedx.wxs" || exit 1
grep -q "PROP_DB_TYPE" "$TMP_DIR/openedx.wxs" || exit 1

# 2. Test WordPress WiX generation
printf '[TEST 2] Synthesizing WiX manifest for WordPress...
'
"$TEMPLATE_SH" "${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress" --out "$TMP_DIR/wordpress.wxs"
grep -q "WordPress" "$TMP_DIR/wordpress.wxs" || exit 1

# 3. Test Drupal WiX generation
printf '[TEST 3] Synthesizing WiX manifest for Drupal...
'
"$TEMPLATE_SH" "${LIBSCRIPT_ROOT_DIR}/stacks/cms/drupal" --out "$TMP_DIR/drupal.wxs"
grep -q "Drupal" "$TMP_DIR/drupal.wxs" || exit 1

# 4. Test Nextcloud WiX generation
printf '[TEST 4] Synthesizing WiX manifest for Nextcloud...
'
"$TEMPLATE_SH" "${LIBSCRIPT_ROOT_DIR}/stacks/collaboration/nextcloud" --out "$TMP_DIR/nextcloud.wxs"
grep -q "Nextcloud" "$TMP_DIR/nextcloud.wxs" || exit 1

printf '[SUCCESS] All Declarative MSI Synthesis Tests Passed!
'
