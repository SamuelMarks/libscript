#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
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
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
[ -z "${LIBSCRIPT_ROOT_DIR:-}" ] && LIBSCRIPT_ROOT_DIR=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; echo "$d")
if [ "$CMD" = "package_as" ]; then
  pkg_type="$1"
  shift
  if [ "$pkg_type" = "docker" ] || [ "$pkg_type" = "dockerfile" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_docker.sh"
  elif [ "$pkg_type" = "docker_compose" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_docker_compose.sh"
  elif [ "$pkg_type" = "TUI" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_tui.sh"
  elif [ "$pkg_type" = "msi" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_msi.sh"
  elif [ "$pkg_type" = "innosetup" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_innosetup.sh"
  elif [ "$pkg_type" = "nsis" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_nsis.sh"
  elif [ "$pkg_type" = "pkg" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_pkg.sh"
  elif [ "$pkg_type" = "dmg" ]; then
    . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/formats/pkg_dmg.sh"
  else
    echo "Error: Unsupported package format '$pkg_type'." >&2
    exit 1
  fi
fi
