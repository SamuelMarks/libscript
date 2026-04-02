#!/bin/sh
# # JupyterHub Stack CLI
#
# This CLI manages the JupyterHub data science stack. It is a thin wrapper 
# around the LibScript component core.

PACKAGE_NAME="jupyterhub"

# Resolve LibScript root
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="$(cd "$(dirname -- "$0")" && pwd)"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

# Source the component core to handle all lifecycle routing
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/component_core.sh"
