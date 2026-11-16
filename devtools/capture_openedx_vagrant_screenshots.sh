#!/bin/sh
# ## Overview
# Backward-compatible wrapper delegating Open edX Vagrant MSI wizard, desktop, LMS, and Studio CMS
# screenshot capture to the generic `experiments/openedx` (`pkg_ui_runner.sh`) pipeline.
# ## Usage
# ./devtools/capture_openedx_vagrant_screenshots.sh [--target-os=windows-11] [--pkg-source=build|github-release] [--dry-run=1]
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

# ## sync_cc0_screenshots
# Copies captured screenshots into ../cc0-assets when present for backward compatibility with docs renderers.
sync_cc0_screenshots() {
  _cc0_dir="${CC0_SCREENSHOTS_DIR:-${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/screenshots/windows}"
  _exp_out="${LIBSCRIPT_ROOT_DIR}/build/experiments/openedx/windows-11/msi"
  if [ -d "$(dirname "$_cc0_dir")" ] && [ -d "$_exp_out" ]; then
    mkdir -p "$_cc0_dir"
    set +f
    for _png in "$_exp_out"/*/screenshots/*.png; do
      if [ -f "$_png" ]; then
        cp "$_png" "$_cc0_dir/"
      fi
    done
    set -f
  fi
}

STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment run openedx --target-os=windows-11 --pkg-format=msi --pkg-source="${PKG_SOURCE:-build}" "$@"
sync_cc0_screenshots
