#!/bin/sh
# ## Overview
# Generic setup script for kvikdos (headless 8086 real-mode DOS CLI runner).
# Compiles kvikdos_c89.c with zero external dependencies and optionally wires win-cmd-asm vm8086.
#
# ## Usage
# ACTION=install ./_lib/toolchains/kvikdos/setup.sh

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
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

for _klib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_klib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${KVIKDOS_VERSION:-0.1.0}"

# ## resolve_exact_version
# Resolves dynamic version aliases into a concrete kvikdos version string.
resolve_exact_version() {
  case "${VERSION}" in
    latest|stable|lts) EXACT_VERSION='0.1.0' ;;
    *) EXACT_VERSION="${VERSION#v}" ;;
  esac
}

case "${ACTION}" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos" || true
    fi
    ;;
  ls-remote)
    printf '0.1.0\n'
    ;;
  download)
    resolve_exact_version
    printf '[INFO] kvikdos %s uses bundled C89 source (_lib/toolchains/kvikdos/src/kvikdos_c89.c).\n' "${EXACT_VERSION}"
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos/${EXACT_VERSION}"
    if [ ! -x "${TARGET_DIR}/bin/kvikdos" ]; then
      log_error "kvikdos ${EXACT_VERSION} is not installed at ${TARGET_DIR}."
      exit 1
    fi
    libscript_symlink_alias 'kvikdos' 'default' "${EXACT_VERSION}"
    ;;
  bootstrap|install)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'kvikdos' "${EXACT_VERSION}")
    if [ -x "${TARGET_DIR}/bin/kvikdos" ] && [ "${FORCE_REINSTALL:-0}" != '1' ]; then
      log_info "kvikdos ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      libscript_symlink_alias 'kvikdos' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'kvikdos' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin"
    STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/compile_host_c89.sh" "${SCRIPT_DIR}/src/kvikdos_c89.c" "${TARGET_DIR}/bin/kvikdos"
    chmod +x "${TARGET_DIR}/bin/kvikdos"
    libscript_symlink_alias 'kvikdos' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'kvikdos' 'default' "${EXACT_VERSION}"
    log_success "kvikdos ${EXACT_VERSION} compiled and installed at ${TARGET_DIR}/bin/kvikdos."
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/kvikdos/${EXACT_VERSION}"
    ;;
  *)
    resolve_exact_version
    TARGET_DIR=$(libscript_get_version_dir 'kvikdos' "${EXACT_VERSION}")
    libscript_handle_generic_action 'kvikdos' "${ACTION}" "${EXACT_VERSION}" 'from-source' '' '' '' "${TARGET_DIR}/bin/kvikdos" "${TARGET_DIR}"
    ;;
esac
