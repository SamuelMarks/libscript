parse_listen() {
  local listen_str="$1"
  local prefix="$2"
  if [ -z "$listen_str" ] || [ "$listen_str" = "null" ]; then
    return
  fi
  if echo "$listen_str" | grep -q '^unix:'; then
    printf '{"%s_LISTEN_SOCKET": "%s"}' "$prefix" "${listen_str#unix:}"
  elif echo "$listen_str" | grep -q ':'; then
    local addr="${listen_str%%:*}"
    local port="${listen_str##*:}"
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
