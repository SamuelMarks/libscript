#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi

# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


parse_listen() {
LISTEN_STR="$1"
PREFIX="$2"
  if [ -z "$LISTEN_STR" ] || [ "$LISTEN_STR" = "null" ]; then
    return
  fi
  if echo "$LISTEN_STR" | grep -q '^unix:'; then
    printf '{"%s_LISTEN_SOCKET": "%s"}' "$PREFIX" "${LISTEN_STR#unix:}"
  elif echo "$LISTEN_STR" | grep -q ':'; then
ADDR="${LISTEN_STR%%:*}"
PORT="${LISTEN_STR##*:}"
    printf '{"%s_LISTEN_ADDRESS": "%s", "%s_LISTEN_PORT": "%s"}' "$PREFIX" "$ADDR" "$PREFIX" "$PORT"
  else
    printf '{"%s_LISTEN_PORT": "%s"}' "$PREFIX" "$LISTEN_STR"
  fi
}
parse_listen "80" "NGINX"
echo
parse_listen "127.0.0.1:80" "NGINX"
echo
parse_listen "unix:/tmp/sock" "NGINX"
echo
