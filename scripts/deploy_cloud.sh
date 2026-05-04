#!/bin/sh
set -feu
exec "${LIBSCRIPT_ROOT_DIR:-${PWD}}/_lib/cloud/core/deploy_cloud.sh" "$@"
