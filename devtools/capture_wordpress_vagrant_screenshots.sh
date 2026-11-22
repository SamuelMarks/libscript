#!/bin/sh
# ## Overview
# Backward-compatible wrapper delegating WordPress Vagrant MSI wizard, desktop, and wp-admin login
# screenshot capture to the generic `experiments/_common/pkg_ui_runner.sh` pipeline.
# ## Usage
# ./devtools/capture_wordpress_vagrant_screenshots.sh [--target-os=windows-11] [--pkg-source=build|github-release] [--dry-run=1]
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

# ## run_wp_generic_experiment
# Scaffolds an ephemeral WordPress installer-e2e suite descriptor if needed and runs pkg_ui_runner.sh.
run_wp_generic_experiment() {
  _wp_suite_root="${LIBSCRIPT_ROOT_DIR}/tests_tmp/experiments/_transient_suites"
  mkdir -p "$_wp_suite_root"
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment scaffold wordpress \
    --template=installer-e2e \
    --packaging-manifest="${LIBSCRIPT_ROOT_DIR}/workloads/apps/wordpress/packaging.json" \
    --out-root="$_wp_suite_root" >/dev/null
  STACK='' sh "${LIBSCRIPT_ROOT_DIR}/experiments/_common/pkg_ui_runner.sh" \
    --suite-dir="${_wp_suite_root}/wordpress" \
    --target-os=windows-11 \
    --pkg-format=msi \
    --pkg-source="${PKG_SOURCE:-build}" \
    "$@"
}

run_wp_generic_experiment "$@"
