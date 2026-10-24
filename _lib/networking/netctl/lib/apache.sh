#!/bin/sh
# ## Overview
# Network control library module for apache.
# Supports SPA FallbackResource and WebSocket RewriteEngine rules.
# 
# ## Usage
# This script provides internal functions and should not be executed directly.

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
: "${NETCTL_DIR:=$(cd "$SCRIPT_DIR/.." && pwd)}"
SCRIPT_NAME="${NETCTL_DIR}/lib/prelude.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# ## netctl_emit_apache
# Performs the netctl_emit_apache operation and updates component state.
netctl_emit_apache() {
  state_file="${1:-$NETCTL_STATE_FILE}"

  if [ ! -f "$state_file" ]; then
    printf '%s
' "Error: State file '$state_file' not found." >&2
    return 1
  fi

  jq -r '.listen[]' "$state_file" | while read -r port; do
    printf '%s
' "Listen $port"
  done
  printf '%s
' ""

  first_port=$(jq -r '.listen[0] // "80"' "$state_file")
  printf '%s
' "<VirtualHost *:$first_port>"

  jq -r '.routes | to_entries[] | "\(.key)\t\(.value.type)\t\(.value.target // "")\t\(.value.pattern // "")"' "$state_file" | while IFS="$(printf '\t')" read -r path type target pattern; do
    case "$type" in
      static)
        printf '    Alias "%s" "%s"\n' "$path" "$target"
        printf '    <Directory "%s">\n' "$target"
        printf '        Require all granted\n'
        printf '    </Directory>\n'
        ;;
      spa)
        printf '    Alias "%s" "%s"\n' "$path" "$target"
        printf '    <Directory "%s">\n' "$target"
        printf '        Require all granted\n'
        printf '        FallbackResource /index.html\n'
        printf '    </Directory>\n'
        ;;
      proxy)
        printf '    ProxyPass "%s" "%s"\n' "$path" "$target"
        printf '    ProxyPassReverse "%s" "%s"\n' "$path" "$target"
        ;;
      ws)
        _ws_target=$(printf '%s\n' "$target" | sed -e 's#^http://#ws://#' -e 's#^https://#wss://#')
        printf '    RewriteEngine On\n'
        printf '    RewriteCond %%{HTTP:Upgrade} websocket [NC]\n'
        printf '    RewriteCond %%{HTTP:Connection} upgrade [NC]\n'
        printf '    RewriteRule ^%s(.*) "%s$1" [P,L]\n' "$path" "$_ws_target"
        printf '    ProxyPass "%s" "%s"\n' "$path" "$target"
        printf '    ProxyPassReverse "%s" "%s"\n' "$path" "$target"
        ;;
      rewrite)
        printf '    RewriteEngine On\n'
        printf '    RewriteRule "^%s(.*)$" "%s" [L]\n' "$path" "$pattern"
        ;;
    esac
  done

  printf '%s
' "</VirtualHost>"
}
