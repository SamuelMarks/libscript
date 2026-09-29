#!/bin/sh
# ## Overview
# Verification test suite for universal branding synthesis.
#
# ## Usage
#   ./tests/test_branding_synthesis.sh

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

SYNTH_SH="${LIBSCRIPT_ROOT_DIR}/packaging/synthesize_branding.sh"

printf '==> Running Universal Branding Synthesis Verification Tests...
'

TEST_OUT="$(mktemp -d "${TMPDIR:-/tmp}/branding_test_XXXXXX")"
trap 'rm -rf "$TEST_OUT"' EXIT INT TERM

# Test synthesizing branding for WordPress
"$SYNTH_SH" "${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress" --output-dir "$TEST_OUT"

[ -f "$TEST_OUT/banner_side.bmp" ] || exit 1
[ -f "$TEST_OUT/banner_top.bmp" ] || exit 1
[ -f "$TEST_OUT/app.ico" ] || exit 1
[ -f "$TEST_OUT/license.rtf" ] || exit 1

# Check BMP header magic bytes
magic=$(od -c "$TEST_OUT/banner_side.bmp" | head -n 1 | awk '{print $2 $3}')
[ "$magic" = "BM" ] || exit 1

printf '[SUCCESS] All Branding Synthesis Verification Tests Passed!
'
