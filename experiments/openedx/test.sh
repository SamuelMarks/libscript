#!/bin/sh
# ## Overview
# Validates the Open edX installer-e2e suite, multi-OS/format dry-run matrix, 2x idempotency, and zero-extension WordPress/Odoo reuse.
# ## Usage
# ./experiments/openedx/test.sh
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
export LIBSCRIPT_ROOT_DIR

TMP_TST=$(mktemp -d)
trap 'rm -rf "$TMP_TST"' EXIT INT TERM

# Test 1: Validate Open edX suite manifest and flag schema
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment validate openedx --target-os=windows-11 --pkg-format=msi --pkg-source=github-release >/dev/null

# Test 2: Verify multi-OS/format dry-run matrix & exact desktop -> LMS (open+login) -> CMS (open+login) order
STACK='' sh "${SCRIPT_DIR}/run.sh" \
  --dry-run=1 \
  --bento-prefix=custom-bento \
  --target-os=windows-11 \
  --pkg-format=msi \
  --pkg-source=github-release \
  --install-modes=headless,quick,custom \
  --results-dir="${TMP_TST}/win_msi" >/dev/null

jq -e '
  .vagrant.bento_box == "custom-bento/windows-11"
  and .artifact.format == "msi"
  and .artifact.source == "github-release"
  and ([.mode_results[].install_mode] == ["headless", "quick", "custom"])
  and ([.mode_results[0].verification_steps[].id] == [
    "10b_desktop_icons",
    "11_browser_lms_focused",
    "13_browser_lms_authenticated",
    "12_browser_studio_focused",
    "14_browser_studio_authenticated"
  ])
' "${TMP_TST}/win_msi/execution_plan.json" >/dev/null

# Test 2b: Linux .deb + build anew & macOS .pkg + build anew
STACK='' sh "${SCRIPT_DIR}/run.sh" --dry-run=1 --target-os=debian-13 --pkg-format=auto --pkg-source=build --results-dir="${TMP_TST}/deb_build" >/dev/null
jq -e '.vagrant.target_os == "debian-13" and .artifact.format == "deb" and .artifact.source == "build"' "${TMP_TST}/deb_build/execution_plan.json" >/dev/null

STACK='' sh "${SCRIPT_DIR}/run.sh" --dry-run=1 --target-os=macos-14-arm64 --pkg-format=auto --pkg-source=build --results-dir="${TMP_TST}/mac_pkg" >/dev/null
jq -e '.vagrant.target_os == "macos-14-arm64" and .artifact.format == "pkg" and .artifact.source == "build"' "${TMP_TST}/mac_pkg/execution_plan.json" >/dev/null

# Test 3: Prove zero-extension reusability for WordPress and Odoo via scaffold --template=installer-e2e
mkdir -p "${TMP_TST}/suites"
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment scaffold wordpress \
  --template=installer-e2e \
  --packaging-manifest="${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/wordpress/packaging.json" \
  --out-root="${TMP_TST}/suites" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment scaffold odoo \
  --template=installer-e2e \
  --packaging-manifest="${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/odoo/packaging.json" \
  --out-root="${TMP_TST}/suites" >/dev/null

STACK='' sh "${TMP_TST}/suites/wordpress/run.sh" --dry-run=1 --results-dir="${TMP_TST}/wp_out" >/dev/null
jq -e '.application == "wordpress" and (.mode_results[0].verification_steps | length >= 3) and (.mode_results[0].verification_steps[1].service_port == 80)' "${TMP_TST}/wp_out/execution_plan.json" >/dev/null

STACK='' sh "${TMP_TST}/suites/odoo/run.sh" --dry-run=1 --results-dir="${TMP_TST}/odoo_out" >/dev/null
jq -e '
  .application == "odoo"
  and ([.mode_results[0].verification_steps[].id] == [
    "10b_desktop_icons",
    "11_browser_odoo_login",
    "12_browser_odoo_authenticated"
  ])
  and (.mode_results[0].verification_steps[2].auth_flow.ready_selector == ".o_main_navbar")
' "${TMP_TST}/odoo_out/execution_plan.json" >/dev/null

# Test 4: Verify 2x rerun idempotency (second run skips cleanly without mutating state)
_rerun_out=$(STACK='' sh "${SCRIPT_DIR}/run.sh" --dry-run=1 --bento-prefix=custom-bento --target-os=windows-11 --pkg-format=msi --pkg-source=github-release --install-modes=headless,quick,custom --results-dir="${TMP_TST}/win_msi")
case "$_rerun_out" in
  *SKIP*) ;;
  *) printf '[FAIL] Expected [SKIP] on idempotent 2x rerun, got: %s\n' "$_rerun_out" >&2; exit 1 ;;
esac

printf '[PASS] Open edX installer-e2e suite & zero-extension WordPress/Odoo reusability verified.\n'
