#!/bin/sh
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi

# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


parse_listen() {
listen_str="$1"
prefix="$2"
  if [ -z "$listen_str" ] || [ "$listen_str" = "null" ]; then
    return
  fi
  if echo "$listen_str" | grep -q '^unix:'; then
    printf '{"%s_LISTEN_SOCKET": "%s"}' "$prefix" "${listen_str#unix:}"
  elif echo "$listen_str" | grep -q ':'; then
addr="${listen_str%%:*}"
port="${listen_str##*:}"
    printf '{"%s_LISTEN_ADDRESS": "%s", "%s_LISTEN_PORT": "%s"}' "$prefix" "$addr" "$prefix" "$port"
  else
    printf '{"%s_LISTEN_PORT": "%s"}' "$prefix" "$listen_str"
  fi
}
parse_listen "80" "NGINX"
echo
parse_listen "127.0.0.1:80" "NGINX"
echo
parse_listen "unix:/tmp/sock" "NGINX"
echo
