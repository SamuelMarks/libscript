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



IS_ACTION=0
REQ_VERSION=0
case "$cmd" in
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
    IS_ACTION=1; REQ_VERSION=1 ;;
  remove|uninstall|status|test|ls|ls-remote)
    IS_ACTION=1 ;;
  run|which|exec|env|download|serve|route)
    IS_ACTION=1; REQ_VERSION=1 ;;
esac

ACTION_PKG="$cmd"
if [ "$IS_ACTION" = "1" ]; then
  ACTION_PKG="$1"
  if [ -z "$ACTION_PKG" ]; then
    echo "Error: package_name is required for $cmd" >&2
    exit 1
  fi
  # We do not shift here because the local cli.sh expects the action as $1
  # But we need to pass "$cmd" "$ACTION_PKG" "$@" to local cli.sh
  # Oh wait, we already shifted. So $1 is action_pkg.
  # Let's restore "$cmd" for the local cli.sh.
  set -- "$cmd" "$@"
fi

TARGET=""
if [ -f "$SCRIPT_DIR/$ACTION_PKG/cli.sh" ]; then
  TARGET="$SCRIPT_DIR/$ACTION_PKG"
else
  matches=$(find_components | grep -i "$ACTION_PKG" || true)
  count=$(echo "$matches" | grep -c . || true)
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$ACTION_PKG'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    TARGET="$SCRIPT_DIR/$matches"
  else
    exact_match=$(echo "$matches" | grep "/$ACTION_PKG$" || true)
    exact_count=$(echo "$exact_match" | grep -c . || true)
    if [ "$exact_count" -eq 1 ]; then
      TARGET="$SCRIPT_DIR/$exact_match"
      echo "Error: Component '$ACTION_PKG' is ambiguous. Matches:"
      echo "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$TARGET/cli.sh" ]; then
  exec "$TARGET/cli.sh" "$@"
elif [ -f "$TARGET/cli.sh" ]; then
  exec sh "$TARGET/cli.sh" "$@"
else
  echo "Error: Local CLI not found in $TARGET"
  exit 1
fi
