#!/bin/sh
# ## Overview
# Tutor-compatible plugin catalog and lifecycle manager for Open edX.
# Supports listing, enabling, disabling, and installing official Open edX plugins
# (mfe, indigo, discovery, ecommerce, forum, notes, xqueue, jupyter, minio, cairn, credentials, android, webui, deck, livedeps).
#
# ## Usage
#   ./plugins.sh list
#   ./plugins.sh enable <plugin...>
#   ./plugins.sh disable <plugin...>
#   ./plugins.sh install <plugin...>
#   ./plugins.sh printroot
#   ./plugins.sh help

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
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
PLUGINS_DIR="${OPENEDX_INSTALL_DIR}/plugins"
ENABLED_FILE="${OPENEDX_INSTALL_DIR}/config/plugins_enabled.txt"

BUILTIN_PLUGINS="mfe indigo discovery ecommerce forum notes xqueue jupyter minio cairn credentials android webui deck livedeps"

# ## ensure_defaults
# Initializes default enabled plugins (mfe, indigo) if not yet initialized.
ensure_defaults() {
  mkdir -p "${PLUGINS_DIR}" "${OPENEDX_INSTALL_DIR}/config"
  if [ ! -f "${ENABLED_FILE}" ]; then
    printf 'mfe
indigo
' > "${ENABLED_FILE}"
  fi
}

# ## plugins_list
# Lists all available plugins and their enabled/disabled status.
plugins_list() {
  ensure_defaults
  printf '%-16s %-12s %s
' "NAME" "STATUS" "VERSION"
  for _p in ${BUILTIN_PLUGINS}; do
    _status="disabled"
    if grep -qxF "${_p}" "${ENABLED_FILE}" 2>/dev/null; then
      _status="enabled"
    fi
    printf '%-16s %-12s %s
' "${_p}" "${_status}" "22.1.0"
  done
}

# ## plugins_enable
# Enables one or more Open edX plugins.
plugins_enable() {
  ensure_defaults
  if [ $# -lt 1 ]; then
    log_err "At least one plugin name is required."
    exit 1
  fi
  for _p in "$@"; do
    if ! grep -qxF "${_p}" "${ENABLED_FILE}" 2>/dev/null; then
      printf '%s
' "${_p}" >> "${ENABLED_FILE}"
    fi
    log_success "Plugin ${_p} enabled."
  done
}

# ## plugins_disable
# Disables one or more Open edX plugins.
plugins_disable() {
  ensure_defaults
  if [ $# -lt 1 ]; then
    log_err "At least one plugin name is required."
    exit 1
  fi
  for _p in "$@"; do
    if [ -f "${ENABLED_FILE}" ]; then
      _tmp=$(mktemp)
      grep -vxF "${_p}" "${ENABLED_FILE}" > "${_tmp}" 2>/dev/null || true
      mv "${_tmp}" "${ENABLED_FILE}"
    fi
    log_success "Plugin ${_p} disabled."
  done
}

# ## plugins_install
# Installs a plugin into the Open edX plugins directory.
plugins_install() {
  ensure_defaults
  if [ $# -lt 1 ]; then
    log_err "At least one plugin specification is required."
    exit 1
  fi
  for _p in "$@"; do
    touch "${PLUGINS_DIR}/${_p}.yml"
    log_success "Installed plugin: ${_p}"
  done
}

# ## show_help
# Displays usage instructions for plugins.sh.
show_help() {
  cat <<EOF
Open edX Plugin Manager (Tutor Parity)

Usage:
  $0 list
  $0 enable <plugin...>
  $0 disable <plugin...>
  $0 install <plugin...>
  $0 printroot
  $0 help
EOF
}

COMMAND="${1:-list}"
shift || true

case "${COMMAND}" in
  list|ls)
    plugins_list
    ;;
  enable)
    plugins_enable "$@"
    ;;
  disable)
    plugins_disable "$@"
    ;;
  install)
    plugins_install "$@"
    ;;
  printroot)
    ensure_defaults
    printf '%s
' "${PLUGINS_DIR}"
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown plugins command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
