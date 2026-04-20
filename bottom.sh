#!/bin/sh
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi

# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



is_action=0
req_version=0
case "$cmd" in
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
    is_action=1; req_version=1 ;;
  remove|uninstall|status|test|ls|ls-remote)
    is_action=1 ;;
  run|which|exec|env|download|serve|route)
    is_action=1; req_version=1 ;;
esac

action_pkg="$cmd"
if [ "$is_action" = "1" ]; then
  action_pkg="$1"
  if [ -z "$action_pkg" ]; then
    echo "Error: package_name is required for $cmd" >&2
    exit 1
  fi
  # We do not shift here because the local cli.sh expects the action as $1
  # But we need to pass "$cmd" "$action_pkg" "$@" to local cli.sh
  # Oh wait, we already shifted. So $1 is action_pkg.
  # Let's restore "$cmd" for the local cli.sh.
  set -- "$cmd" "$@"
fi

target=""
if [ -f "$SCRIPT_DIR/$action_pkg/cli.sh" ]; then
  target="$SCRIPT_DIR/$action_pkg"
else
  matches=$(find_components | grep -i "$action_pkg" || true)
  count=$(echo "$matches" | grep -c . || true)
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$action_pkg'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    target="$SCRIPT_DIR/$matches"
  else
    exact_match=$(echo "$matches" | grep "/$action_pkg$" || true)
    exact_count=$(echo "$exact_match" | grep -c . || true)
    if [ "$exact_count" -eq 1 ]; then
      target="$SCRIPT_DIR/$exact_match"
      echo "Error: Component '$action_pkg' is ambiguous. Matches:"
      echo "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$target/cli.sh" ]; then
  exec "$target/cli.sh" "$@"
elif [ -f "$target/cli.sh" ]; then
  exec sh "$target/cli.sh" "$@"
else
  echo "Error: Local CLI not found in $target"
  exit 1
fi
