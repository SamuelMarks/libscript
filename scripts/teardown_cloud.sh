#!/bin/sh
set -feu
exec "${LIBSCRIPT_ROOT_DIR:-${PWD}}/_lib/cloud/core/teardown_cloud.sh" "$@"
