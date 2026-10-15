#!/bin/sh
# ## Overview
# Verification test for WordPress 7.1.2 reverse-proxy header trust and ingress SSL termination.
# Validates that wp-config.php detects HTTP_X_FORWARDED_PROTO and sets HTTPS='on'.
#
# ## Usage
#   ./tests/test_wordpress_reverse_proxy.sh

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

printf '==> Testing WordPress Reverse-Proxy Ingress Configuration...\n'

TMP_WWW=$(mktemp -d)

"${LIBSCRIPT_ROOT_DIR}/stacks/cms/wordpress/setup_generic.sh" --wwwroot "$TMP_WWW" --skip-deps --server-name "wp.example.com" --site-url "https://wp.example.com" --home-url "https://wp.example.com"

WP_CONFIG="${TMP_WWW}/wp-config.php"

if ! grep -q "HTTP_X_FORWARDED_PROTO" "$WP_CONFIG"; then
  printf '[ERROR] HTTP_X_FORWARDED_PROTO stanza missing from wp-config.php!\n' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

if ! grep -q "HTTP_X_FORWARDED_HOST" "$WP_CONFIG"; then
  printf '[ERROR] HTTP_X_FORWARDED_HOST stanza missing from wp-config.php!\n' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

if ! grep -q "define( *'WP_SITEURL', *'https://wp.example.com'" "$WP_CONFIG"; then
  printf '[ERROR] Canonical HTTPS WP_SITEURL not configured!\n' >&2
  rm -rf "$TMP_WWW"
  exit 1
fi

rm -rf "$TMP_WWW"
printf '==> Reverse-proxy ingress verification succeeded!\n'
exit 0
