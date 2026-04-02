#!/bin/sh
# # LibScript Common Generic Setup
#
# ## Overview
# This script provides fallback installation logic using the LibScript 
# package manager mapper. It is invoked when no OS-specific setup script 
# is found for a component.
#
# ## Usage
# Sourced by `setup_base.sh` if `setup_<os>.sh` is missing.

set -feu

# Component name should be set by the caller (component_core.sh sets PACKAGE_NAME)
_PKG_MGR_NAME="${PACKAGE_NAME:-}"

if [ -z "${_PKG_MGR_NAME}" ]; then
  # Fallback: try to get it from the directory name if not set
  _PKG_MGR_NAME=$(basename "$(pwd)")
fi

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Attempt to install via the detected package manager
depends "${_PKG_MGR_NAME}"
