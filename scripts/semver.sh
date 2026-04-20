#!/bin/sh
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: $0 [OPTIONS]"
  echo "See script source or documentation for more details."
  exit 0
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <version> <constraint>"
    exit 2
fi

SCRIPT_DIR=$(dirname "$0")

jq -e -L "$SCRIPT_DIR" -n --arg v "$1" --arg c "$2" "include \"semver\"; semver_satisfies(\$v; \$c)" >/dev/null 2>&1
exit $?
