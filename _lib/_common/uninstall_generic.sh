#!/bin/sh
# ## Overview
# Provides fallback uninstallation logic for components on Unix systems.
# It handles delegating to third-party managers like mise/asdf/vfox,
# or safely removing the isolated native installation directories.
#
# ## Usage
# Typically called internally by uninstall.sh.

set -feu
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

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

COMPONENT_NAME="${PACKAGE_NAME:-$(basename "${DIR}")}"
COMPONENT_UPPER="$(printf '%s\n' "$COMPONENT_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"
eval "INSTALL_METHOD=\${${COMPONENT_UPPER}_INSTALL_METHOD:-\${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-libscript_native}}"

if [ "$INSTALL_METHOD" = "system" ]; then
    log_info "Uninstalling ${COMPONENT_NAME} via system package manager is not implemented."
    exit 0
elif [ "$INSTALL_METHOD" = "mise" ]; then
    if [ -n "${VERSION:-}" ]; then
        mise uninstall "${COMPONENT_NAME}@${VERSION}"
    else
        log_info "Please specify a version to uninstall with mise."
    fi
elif [ "$INSTALL_METHOD" = "asdf" ]; then
    if [ -n "${VERSION:-}" ]; then
        asdf uninstall "${COMPONENT_NAME}" "${VERSION}"
    else
        log_info "Please specify a version to uninstall with asdf."
    fi
elif [ "$INSTALL_METHOD" = "pkgx" ]; then
    log_info "Uninstall is not supported via pkgx."
elif [ "$INSTALL_METHOD" = "vfox" ]; then
    if [ -n "${VERSION:-}" ]; then
        vfox uninstall "${COMPONENT_NAME}@${VERSION}"
    else
        log_info "Please specify a version to uninstall with vfox."
    fi
else
    if [ -n "${VERSION:-}" ]; then
        TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/${COMPONENT_NAME}/${VERSION}"
        if [ -L "$TARGET_DIR" ]; then
            EXACT_DIR=$(readlink "$TARGET_DIR")
            log_info "Removing alias ${VERSION} and its target ${EXACT_DIR}..."
            rm -f "$TARGET_DIR"
            if [ -n "$EXACT_DIR" ]; then
                case "$EXACT_DIR" in
                    /*) rm -rf "$EXACT_DIR" ;;
                    *) rm -rf "$(dirname "${TARGET_DIR:?}")/${EXACT_DIR:?}" ;;
                esac
            fi
        elif [ -d "$TARGET_DIR" ]; then
            log_info "Removing ${TARGET_DIR}..."
            rm -rf "$TARGET_DIR"
        else
            log_info "${COMPONENT_NAME} version ${VERSION} is not installed natively at ${TARGET_DIR}."
        fi
    else
        if [ -z "${VERSION:-}" ]; then
             log_info "Removing all native installations of ${COMPONENT_NAME}..."
             rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/${COMPONENT_NAME}"
        fi
    fi
fi
