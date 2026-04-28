#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
if [ "$cmd" = "package_as" ]; then
  pkg_type="$1"
  shift
  if [ "$pkg_type" = "docker" ] || [ "$pkg_type" = "dockerfile" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_docker.sh"
  elif [ "$pkg_type" = "docker_compose" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_docker_compose.sh"
  elif [ "$pkg_type" = "TUI" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_tui.sh"
  elif [ "$pkg_type" = "msi" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_msi.sh"
  elif [ "$pkg_type" = "innosetup" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_innosetup.sh"
  elif [ "$pkg_type" = "nsis" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_nsis.sh"
  elif [ "$pkg_type" = "pkg" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_pkg.sh"
  elif [ "$pkg_type" = "dmg" ]; then
    . "$SCRIPT_DIR/cli/commands/packaging/formats/pkg_dmg.sh"
  else
    echo "Error: Unsupported package format '$pkg_type'." >&2
    exit 1
  fi
fi
