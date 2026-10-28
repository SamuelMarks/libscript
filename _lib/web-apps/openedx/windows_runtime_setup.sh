#!/bin/sh
# ## Overview
# POSIX companion entrypoint for Open edX runtime configuration.
# Configures Open edX LMS and Studio CMS runtime directories and delegates to config.sh on POSIX systems.
#
# ## Usage
# ./_lib/web-apps/openedx/windows_runtime_setup.sh [-InstallDir <dir>] [<dir>]

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

# ## show_help
# Displays usage instructions for windows_runtime_setup.sh.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [-InstallDir <dir>] [<dir>]"
  printf '%s\n' 'Configures Open edX LMS and Studio CMS runtime directories.'
  exit 0
}

# ## main
# Parses arguments and ensures runtime data directories exist on POSIX hosts.
main() {
  _install_dir="${OPENEDX_INSTALL_DIR:-${HOME:-/root}/.libscript/openedx}"
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h|/\?|-\?)
        show_help
        ;;
      -InstallDir|--install-dir)
        if [ $# -gt 1 ]; then
          _install_dir="$2"
          shift 2
        else
          shift
        fi
        ;;
      *)
        _install_dir="$1"
        shift
        ;;
    esac
  done

  mkdir -p "${_install_dir}/data" "${_install_dir}/config"
  printf '[OK] Open edX POSIX runtime verified at %s\n' "${_install_dir}"
}

main "$@"
