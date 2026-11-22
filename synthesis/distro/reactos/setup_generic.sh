#!/bin/sh
# ## Overview
# Generic setup module for reactos-distro.
#
# ## Usage
# ./synthesis/distro/reactos/setup_generic.sh

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

for LIB in "engine/common/pkg_mgr.sh" "engine/common/os_info.sh" "engine/common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ACTION="${ACTION:-install}"
VERSION="${REACTOS_DISTRO_VERSION:-0.4.16}"
[ "$VERSION" = 'latest' ] && VERSION='0.4.16'

case "$ACTION" in
  ls-remote)
    printf '0.4.15\n0.4.16\nnightly\n'
    ;;
  install|bootstrap)
    _home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
    _inst="${_home}/reactos-distro/${VERSION}"
    if [ -x "${_inst}/bin/reactos-distro" ]; then
      log_info "[SKIP] reactos-distro ${VERSION} already installed at ${_inst}."
      exit 0
    fi
    mkdir -p "${_inst}/bin" "${_home}/bin"
    cat <<WRAP > "${_inst}/bin/reactos-distro"
#!/bin/sh
exec "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/cli.sh" "\$@"
WRAP
    chmod +x "${_inst}/bin/reactos-distro"
    ln -sf "${_inst}/bin/reactos-distro" "${_home}/bin/reactos-distro"
    log_info "Installed reactos-distro ${VERSION} to ${_inst}."
    ;;
  assemble)
    STACK='' "${SCRIPT_DIR}/assemble.sh"
    ;;
  *)
    libscript_handle_generic_action 'reactos-distro' "$ACTION" "$VERSION" 'libscript_native'
    ;;
esac
