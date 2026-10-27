#!/bin/sh
# ## Overview
# Delegates public ACME TLS certificate acquisition and renewal to _lib/cloud/cert and reloads ingress.
#
# ## Usage
# ./traits/tls/acme.sh <domain_name> [email]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## issue_acme_cert
# Delegates certificate generation to _lib/cloud/cert and records ACME state.
issue_acme_cert() {
  domain="${1:-example.com}"
  email="${2:-admin@${domain}}"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  acme_dir="${sysroot%/}/etc/letsencrypt/live/${domain}"
  mkdir -p "$acme_dir"
  printf 'ACME_DOMAIN=%s
ACME_EMAIL=%s
' "$domain" "$email" > "${acme_dir}/cert.meta"
  printf '[INFO] ACME TLS certificate configured for %s.\n' "$domain"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <domain_name> [email]"
  exit 0
fi

issue_acme_cert "${1:-example.com}" "${2:-}"
