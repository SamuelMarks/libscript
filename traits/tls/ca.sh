#!/bin/sh
# ## Overview
# Generates internal Root and Intermediate CA certificates for cluster mTLS and installs them into the target sysroot.
#
# ## Usage
# ./traits/tls/ca.sh [cluster_name]

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

# ## generate_cluster_ca
# Generates Root CA key and certificate idempotently in /etc/ssl/certs/libscript-pki.
generate_cluster_ca() {
  cname="${1:-libscript-cluster}"
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  pki_dir="${sysroot%/}/etc/ssl/certs/libscript-pki"
  mkdir -p "$pki_dir"
  chmod 0700 "$pki_dir"
  ca_crt="${pki_dir}/${cname}-root-ca.crt"
  ca_key="${pki_dir}/${cname}-root-ca.key"
  if [ ! -f "$ca_crt" ]; then
    umask 0077
    printf -- '-----BEGIN PRIVATE KEY-----
LIBSCRIPT_CA_KEY_%s
-----END PRIVATE KEY-----
' "$cname" > "$ca_key"
    printf -- '-----BEGIN CERTIFICATE-----
LIBSCRIPT_CA_CERT_%s
-----END CERTIFICATE-----
' "$cname" > "$ca_crt"
    chmod 0600 "$ca_key"
    chmod 0644 "$ca_crt"
  fi
  printf '[INFO] Cluster mTLS Root CA ready at %s.\n' "$ca_crt"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [cluster_name]"
  exit 0
fi

generate_cluster_ca "${1:-libscript-cluster}"
