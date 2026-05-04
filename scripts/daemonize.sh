#!/bin/sh
set -feu
exec "${LIBSCRIPT_ROOT_DIR:-${PWD}}/_lib/init-systems/daemonize.sh" "$@"
