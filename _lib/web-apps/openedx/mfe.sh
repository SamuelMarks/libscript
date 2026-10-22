#!/bin/sh
# ## Overview
# Micro-Frontend (MFE) build, configuration, and delivery pipeline for Open edX.
# Manages learning, authn, account, and course-authoring MFEs.
#
# ## Usage
#   ./mfe.sh build <mfe_name> [--version <version>]
#   ./mfe.sh deploy <mfe_name> [--dest <path>]
#   ./mfe.sh list
#   ./mfe.sh help
#
# ## Parameters
# - `build`: Clones MFE source repository and runs production npm build.
# - `deploy`: Configures runtime env variables and publishes dist artifacts to web directory.
# - `list`: Lists available and built Micro-Frontends.
#
# ## Environment Variables
# - `OPENEDX_INSTALL_DIR`: Path to openedx installation directory.
# - `LIBSCRIPT_ROOT_DIR`: Root directory of LibScript repository.
#
# ## Exit Codes
# - `0`: Success.
# - `1`: Node.js or build pipeline error.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
MFE_ROOT_DIR="${OPENEDX_INSTALL_DIR}/mfes"
MFE_DIST_DIR="${OPENEDX_INSTALL_DIR}/mfe_dist"
MFE_HELPER="${SCRIPT_DIR}/mfe_helper.sh"

mkdir -p "${MFE_ROOT_DIR}" "${MFE_DIST_DIR}"

# ## mfe_build
# Builds an MFE bundle via mfe_helper.sh.
#
# Inputs:
#   $1 - name
#   --version <version>
mfe_build() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 build <mfe_name> [--version <version>]"
    return 1
  fi
  _name="$1"
  shift

  _version="release/verawood.1"
  while [ $# -gt 0 ]; do
    case "$1" in
      --version)
        [ $# -ge 2 ] || { log_err "Option --version requires a value"; return 1; }
        _version="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  log_info "Building Micro-Frontend '${_name}' (version: ${_version})..."
  "${MFE_HELPER}" build "${MFE_ROOT_DIR}" "${_name}" "${_version}"
}

# ## mfe_deploy
# Publishes MFE dist directory via mfe_helper.sh.
#
# Inputs:
#   $1 - name
#   --dest <path>
mfe_deploy() {
  if [ $# -lt 1 ]; then
    log_err "Usage: $0 deploy <mfe_name> [--dest <path>]"
    return 1
  fi
  _name="$1"
  shift

  _dest=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dest)
        [ $# -ge 2 ] || { log_err "Option --dest requires a value"; return 1; }
        _dest="$2"
        shift 2
        ;;
      *)
        log_err "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  log_info "Deploying '${_name}' MFE..."
  "${MFE_HELPER}" deploy "${MFE_ROOT_DIR}" "${MFE_DIST_DIR}" "${_name}" "${_dest}"
}

# ## mfe_list
# Lists all managed MFEs via mfe_helper.sh.
mfe_list() {
  log_info "Listing Open edX Micro-Frontends (MFEs)..."
  printf '============================================================\n'
  "${MFE_HELPER}" list "${MFE_ROOT_DIR}"
  printf '============================================================\n'
}

# ## show_help
# Displays usage guide.
show_help() {
  cat <<EOF
Open edX Micro-Frontend (MFE) Pipeline CLI

Usage:
  $0 build <mfe_name> [--version <version>]
  $0 deploy <mfe_name> [--dest <path>]
  $0 list
  $0 help

Available MFEs:
  learning, authn, account, course-authoring

Commands:
  build     Clone and build production MFE bundles
  deploy    Configure runtime environment and deploy assets
  list      List registered MFEs and deployment status
  help      Show this help message
EOF
}

COMMAND="${1:-help}"
shift || true

case "${COMMAND}" in
  build)
    mfe_build "$@"
    ;;
  deploy)
    mfe_deploy "$@"
    ;;
  list)
    mfe_list
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown MFE command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
