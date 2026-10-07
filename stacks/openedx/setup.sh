#!/bin/sh
# ## Overview
# Open edX Native Deployment Script.
#
# ## Usage
# ./setup.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE[0]-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
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
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

. "$LIBSCRIPT_ROOT_DIR/_lib/_common/log.sh"

log_info "Installing Open edX system dependencies..."
# Build Toolchains & System Headers
# Use package manager agnostic libscript.sh dependency resolver
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install toolchains/git python nodejs
# Only install Unix-specific C headers if not on Windows
if [ "$(uname -s)" != "Windows_NT" ] && [ "$(uname -s)" != "CYGWIN"* ] && [ "$(uname -s)" != "MINGW"* ]; then
    "$LIBSCRIPT_ROOT_DIR/libscript.sh" install libmysqlclient libxml2 libxslt libjpeg openssl gettext
fi

log_info "Installing Open edX databases and caches..."
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install postgres
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install mongodb
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install redis
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install memcached
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install elasticsearch

log_info "Installing Open edX Web Server / Reverse Proxy..."
WEB_SERVER="${LIBSCRIPT_WEB_SERVER:-nginx}"
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install "$WEB_SERVER"

log_info "Installing Application Server..."
# Typically gunicorn for python wsgi
"$LIBSCRIPT_ROOT_DIR/libscript.sh" install gunicorn

log_info "Open edX dependencies installed successfully."

# In Phase 5 & 6, we would execute the proxy provisioning
PROXY_PROVISION="$LIBSCRIPT_ROOT_DIR/_lib/web-servers/provision_proxy.sh"
if [ -f "$PROXY_PROVISION" ]; then
    log_info "Provisioning Web Proxy..."
    # A mock manifest would be supplied here in a real scenario
    # "$PROXY_PROVISION" "$SCRIPT_DIR/proxy_manifest.json"
fi

exit 0
