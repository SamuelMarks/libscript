#!/bin/sh
set -feu
exec "${LIBSCRIPT_ROOT_DIR:-${PWD}}/_lib/orchestration/resolve_stack.sh" "$@"
