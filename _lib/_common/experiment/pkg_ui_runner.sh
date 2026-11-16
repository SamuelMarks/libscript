#!/bin/sh
# ## Overview
# Top-level generic orchestrator composing Steps 0-5 (Bento/Vagrant, package resolution, 3x clean-snapshot installs, and guest UI/browser login verification).
# ## Usage
# ./_lib/_common/experiment/pkg_ui_runner.sh --suite-dir=<dir> [--phase=run|provision|sync|collect|teardown] [--target-os=<os>] [--pkg-format=<fmt>] [--pkg-source=github-release|build] [--install-modes=headless,quick,custom] [--dry-run=1]
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

for _pur_lib in \
  '_lib/_common/os_info.sh' \
  '_lib/_common/experiment/vagrant_substrate.sh' \
  '_lib/_common/experiment/pkg_resolver.sh' \
  '_lib/_common/experiment/guest_ui_verify.sh' \
  '_lib/_common/experiment/install_modes.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_pur_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "$SCRIPT_NAME"
done
unset SCRIPT_NAME || true

# ## pur_show_help
# Prints CLI options for pkg_ui_runner.sh.
pur_show_help() {
  printf '%s\n' 'Usage: pkg_ui_runner.sh --suite-dir=<dir> [--phase=run|provision|sync|collect|teardown] [--results-dir=<dir>] [--target-os=<os>] [--bento-prefix=<prefix>] [--bento-dir=<dir>] [--provider=<prov>] [--pkg-format=<fmt>] [--pkg-source=github-release|build] [--release-repo=<owner/repo>] [--release-tag=<tag>] [--install-modes=headless,quick,custom] [--force-rebuild=0|1] [--dry-run=0|1]'
}

PUR_SUITE_DIR="${SUITE_DIR:-}"
PUR_PHASE="${EXPERIMENT_PHASE:-run}"
PUR_RESULTS_DIR=''
PUR_TARGET_OS="${TARGET_OS:-}"
PUR_BENTO_PREFIX="${BENTO_PREFIX:-}"
PUR_BENTO_DIR="${BENTO_DIR:-}"
PUR_PROVIDER="${PROVIDER:-}"
PUR_PKG_FORMAT="${PKG_FORMAT:-}"
PUR_PKG_SOURCE="${PKG_SOURCE:-}"
PUR_RELEASE_REPO="${RELEASE_REPO:-}"
PUR_RELEASE_TAG="${RELEASE_TAG:-}"
PUR_INSTALL_MODES="${INSTALL_MODES:-}"
PUR_FORCE_REBUILD="${FORCE_REBUILD:-0}"
PUR_DRY_RUN="${DRY_RUN:-0}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) pur_show_help; exit 0 ;;
    --suite-dir=*) PUR_SUITE_DIR="${1#*=}"; shift ;;
    --phase=*) PUR_PHASE="${1#*=}"; shift ;;
    --results-dir=*) PUR_RESULTS_DIR="${1#*=}"; shift ;;
    --target-os=*) PUR_TARGET_OS="${1#*=}"; shift ;;
    --bento-prefix=*) PUR_BENTO_PREFIX="${1#*=}"; shift ;;
    --bento-dir=*) PUR_BENTO_DIR="${1#*=}"; shift ;;
    --provider=*) PUR_PROVIDER="${1#*=}"; shift ;;
    --pkg-format=*) PUR_PKG_FORMAT="${1#*=}"; shift ;;
    --pkg-source=*) PUR_PKG_SOURCE="${1#*=}"; shift ;;
    --release-repo=*) PUR_RELEASE_REPO="${1#*=}"; shift ;;
    --release-tag=*) PUR_RELEASE_TAG="${1#*=}"; shift ;;
    --install-modes=*) PUR_INSTALL_MODES="${1#*=}"; shift ;;
    --force-rebuild=*) PUR_FORCE_REBUILD="${1#*=}"; shift ;;
    --dry-run=*) PUR_DRY_RUN="${1#*=}"; shift ;;
    --render-latex) PUR_PHASE='render-latex'; shift ;;
    *) shift ;;
  esac
done

[ -n "$PUR_SUITE_DIR" ] || { printf '[ERROR] --suite-dir=<dir> is required.\n' >&2; exit 1; }
PUR_SUITE_JSON="${PUR_SUITE_DIR}/suite.json"
[ -f "$PUR_SUITE_JSON" ] || { printf '[ERROR] suite.json not found at %s\n' "$PUR_SUITE_JSON" >&2; exit 1; }

PUR_SUITE_ID=$(jq -r '.id' "$PUR_SUITE_JSON")
PUR_MANIFEST_REL=$(jq -r '.installer_e2e.packaging_manifest' "$PUR_SUITE_JSON")
case "$PUR_MANIFEST_REL" in
  /*) PUR_MANIFEST="$PUR_MANIFEST_REL" ;;
  *) PUR_MANIFEST="${PUR_SUITE_DIR}/${PUR_MANIFEST_REL}" ;;
esac
[ -f "$PUR_MANIFEST" ] || { printf '[ERROR] packaging_manifest not found at %s\n' "$PUR_MANIFEST" >&2; exit 1; }

if [ -z "$PUR_RESULTS_DIR" ]; then
  PUR_RESULTS_DIR="${LIBSCRIPT_ROOT_DIR}/build/experiments/${PUR_SUITE_ID}"
fi
mkdir -p "$PUR_RESULTS_DIR"

[ -n "$PUR_TARGET_OS" ] || PUR_TARGET_OS=$(jq -r '.installer_e2e.vagrant.default_target_os // "windows-11"' "$PUR_SUITE_JSON")
[ -n "$PUR_BENTO_PREFIX" ] || PUR_BENTO_PREFIX=$(jq -r '.installer_e2e.vagrant.bento_prefix // "bento"' "$PUR_SUITE_JSON")
[ -n "$PUR_BENTO_DIR" ] || PUR_BENTO_DIR=$(jq -r '.installer_e2e.vagrant.bento_dir // empty' "$PUR_SUITE_JSON")
[ -n "$PUR_PROVIDER" ] || PUR_PROVIDER=$(jq -r '.installer_e2e.vagrant.provider // "auto"' "$PUR_SUITE_JSON")
[ -n "$PUR_PKG_FORMAT" ] || PUR_PKG_FORMAT=$(jq -r '.installer_e2e.artifact.default_format // "auto"' "$PUR_SUITE_JSON")
[ -n "$PUR_PKG_SOURCE" ] || PUR_PKG_SOURCE=$(jq -r '.installer_e2e.artifact.default_source // "github-release"' "$PUR_SUITE_JSON")
[ -n "$PUR_RELEASE_REPO" ] || PUR_RELEASE_REPO=$(jq -r '.installer_e2e.artifact.release_repo // "SamuelMarks/libscript"' "$PUR_SUITE_JSON")
[ -n "$PUR_RELEASE_TAG" ] || PUR_RELEASE_TAG=$(jq -r '.installer_e2e.artifact.release_tag // "latest"' "$PUR_SUITE_JSON")
if [ -z "$PUR_INSTALL_MODES" ]; then
  PUR_INSTALL_MODES=$(jq -r '(.installer_e2e.install_matrix.modes // ["headless","quick","custom"]) | join(",")' "$PUR_SUITE_JSON")
fi

PUR_RESOLVED_OS=$(vs_resolve_target_os "$PUR_TARGET_OS")
PUR_OS_FAM=$(vs_guest_os_family "$PUR_RESOLVED_OS")
PUR_RESOLVED_PROV=$(vs_resolve_provider "$PUR_PROVIDER")
PUR_RESOLVED_FMT=$(pr_infer_format_for_os "$PUR_RESOLVED_OS" "$PUR_PKG_FORMAT")
PUR_SNAP_NAME=$(jq -r '.installer_e2e.vagrant.vanilla_snapshot_name // "vanilla"' "$PUR_SUITE_JSON")
PUR_CPUS=$(jq -r '.installer_e2e.vagrant.cpus // 4' "$PUR_SUITE_JSON")
PUR_MEM=$(jq -r '.installer_e2e.vagrant.memory_mb // 8192' "$PUR_SUITE_JSON")
PUR_BOX_URL_TPL=$(jq -r '.installer_e2e.vagrant.box_url_template // empty' "$PUR_SUITE_JSON")
PUR_BUILD_VAR=$(jq -r '.installer_e2e.artifact.build_variant // "offline"' "$PUR_SUITE_JSON")
PUR_ASSET_PAT=$(jq -r --arg f "$PUR_RESOLVED_FMT" '.installer_e2e.artifact.release_asset_patterns[$f] // empty' "$PUR_SUITE_JSON")

# ## pur_aggregate_metrics
# Combines per-mode result.json files and provenance metadata into `<results_dir>/metrics.json`.
pur_aggregate_metrics() {
  _pur_pkg_path="${1:-dry-run}"
  _pur_pkg_sha="${2:-dry-run}"
  _pur_status="${3:-converged}"
  _pur_git=$(git -C "$LIBSCRIPT_ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')
  _pur_ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  _pur_app=$(jq -r '.name // "app"' "$PUR_MANIFEST")
  _pur_ver=$(jq -r '.version // "1.0.0"' "$PUR_MANIFEST")
  _pur_ver_plan=$(guv_build_ordered_plan "$PUR_SUITE_JSON" "$PUR_MANIFEST")

  _pur_modes_tmp="${PUR_RESULTS_DIR}/.modes_agg.jsonl"
  : > "$_pur_modes_tmp"
  _pur_oifs="$IFS"
  IFS=','
  for _pur_m in $PUR_INSTALL_MODES; do
    _pur_rf="${PUR_RESULTS_DIR}/${PUR_RESOLVED_OS}/${PUR_RESOLVED_FMT}/${_pur_m}/result.json"
    if [ -f "$_pur_rf" ]; then
      jq -c '.' "$_pur_rf" >> "$_pur_modes_tmp"
    else
      jq -nc --arg m "$_pur_m" --arg snap "$PUR_SNAP_NAME" --argjson vp "$_pur_ver_plan" \
        '{install_mode:$m,snapshot_restored:$snap,status:"planned",verification_steps:$vp}' >> "$_pur_modes_tmp"
    fi
  done
  IFS="$_pur_oifs"

  _pur_modes_arr=$(jq -s '.' "$_pur_modes_tmp")
  rm -f "$_pur_modes_tmp"

  jq -n \
    --arg sid "$PUR_SUITE_ID" \
    --arg app "$_pur_app" \
    --arg ver "$_pur_ver" \
    --arg git "$_pur_git" \
    --arg ts "$_pur_ts" \
    --arg hos "${UNAME_LOWER:-unknown}" \
    --arg arch "${ARCH:-unknown}" \
    --arg gos "$PUR_RESOLVED_OS" \
    --arg fam "$PUR_OS_FAM" \
    --arg box "${PUR_BENTO_PREFIX}/${PUR_RESOLVED_OS}" \
    --arg prov "$PUR_RESOLVED_PROV" \
    --arg snap "$PUR_SNAP_NAME" \
    --arg fmt "$PUR_RESOLVED_FMT" \
    --arg src "$PUR_PKG_SOURCE" \
    --arg repo "$PUR_RELEASE_REPO" \
    --arg tag "$PUR_RELEASE_TAG" \
    --arg pkg "$_pur_pkg_path" \
    --arg sha "$_pur_pkg_sha" \
    --arg st "$_pur_status" \
    --argjson modes "$_pur_modes_arr" \
    '{
      suite_id: $sid,
      application: $app,
      application_version: $ver,
      git_commit: $git,
      generated_at: $ts,
      host_os: $hos,
      host_arch: $arch,
      vagrant: {
        bento_box: $box,
        target_os: $gos,
        os_family: $fam,
        provider: $prov,
        vanilla_snapshot: $snap
      },
      artifact: {
        format: $fmt,
        source: $src,
        release_repo: $repo,
        release_tag: $tag,
        resolved_path: $pkg,
        sha256: $sha
      },
      mode_results: $modes,
      status: $st
    }' > "${PUR_RESULTS_DIR}/metrics.json.tmp"
  mv "${PUR_RESULTS_DIR}/metrics.json.tmp" "${PUR_RESULTS_DIR}/metrics.json"
}

# ## pur_execute_dry_run
# Emits deterministic execution_plan.json and metrics.json without booting a Vagrant hypervisor.
pur_execute_dry_run() {
  _pur_key="${PUR_SUITE_ID}:${PUR_BENTO_PREFIX}:${PUR_RESOLVED_OS}:${PUR_RESOLVED_PROV}:${PUR_RESOLVED_FMT}:${PUR_PKG_SOURCE}:${PUR_INSTALL_MODES}"
  _pur_stamp="${PUR_RESULTS_DIR}/.dry_run_stamp"
  if [ "$PUR_FORCE_REBUILD" != '1' ] && [ -f "$_pur_stamp" ] && [ "$(cat "$_pur_stamp")" = "$_pur_key" ] && [ -s "${PUR_RESULTS_DIR}/metrics.json" ]; then
    printf '[SKIP] Dry-run plan for %s (%s/%s) already converged at %s\n' "$PUR_SUITE_ID" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_FMT" "$PUR_RESULTS_DIR"
    return 0
  fi

  pur_aggregate_metrics "dry-run://${PUR_PKG_SOURCE}/${PUR_SUITE_ID}.${PUR_RESOLVED_FMT}" 'dry-run-sha256' 'dry_run_planned'
  cp "${PUR_RESULTS_DIR}/metrics.json" "${PUR_RESULTS_DIR}/execution_plan.json"
  printf '%s\n' "$_pur_key" > "$_pur_stamp"
  printf '[OK] Dry-run installer-e2e plan emitted -> %s/execution_plan.json\n' "$PUR_RESULTS_DIR"
}

case "$PUR_PHASE" in
  provision)
    if [ "$PUR_DRY_RUN" = '1' ]; then
      pur_execute_dry_run
      exit 0
    fi
    vs_register_bento_box "$PUR_BENTO_PREFIX" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_PROV" "$PUR_BENTO_DIR" "$PUR_BOX_URL_TPL" >/dev/null
    vs_prepare_workspace "$PUR_SUITE_ID" "$PUR_BENTO_PREFIX" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_PROV" "$PUR_CPUS" "$PUR_MEM" >/dev/null
    printf '[PROVISION] Prepared Vagrant workspace for %s/%s (%s)\n' "$PUR_BENTO_PREFIX" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_PROV"
    exit 0
    ;;
  sync)
    if [ "$PUR_DRY_RUN" = '1' ]; then
      pur_execute_dry_run
      exit 0
    fi
    pr_resolve_artifact "$PUR_SUITE_ID" "$PUR_MANIFEST" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_FMT" "$PUR_PKG_SOURCE" "$PUR_RELEASE_REPO" "$PUR_RELEASE_TAG" "$PUR_ASSET_PAT" "$PUR_BUILD_VAR" "$PUR_FORCE_REBUILD" >/dev/null
    printf '[SYNC] Synchronized installer artifact for %s (%s)\n' "$PUR_SUITE_ID" "$PUR_RESOLVED_FMT"
    exit 0
    ;;
  collect)
    pur_aggregate_metrics 'collected' 'collected' 'collected'
    printf '[COLLECT] Aggregated installer-e2e metrics -> %s/metrics.json\n' "$PUR_RESULTS_DIR"
    exit 0
    ;;
  teardown)
    _pur_ws="${LIBSCRIPT_ROOT_DIR}/tests_tmp/experiments/${PUR_SUITE_ID}/${PUR_RESOLVED_OS}-${PUR_RESOLVED_PROV}"
    vs_teardown_vm "$_pur_ws" "${DESTROY_VM:-0}"
    printf '[TEARDOWN] Halted Vagrant workspace %s\n' "$_pur_ws"
    exit 0
    ;;
  render-latex)
    printf '\\newcommand{\\ExpSuiteId}{%s}\n' "$PUR_SUITE_ID" > "${PUR_RESULTS_DIR}/macros.tex"
    exit 0
    ;;
  run)
    if [ "$PUR_DRY_RUN" = '1' ]; then
      pur_execute_dry_run
      exit 0
    fi

    # Step 0: Register Bento fork box, prepare Vagrant workspace, boot VM, and save clean vanilla snapshot
    vs_register_bento_box "$PUR_BENTO_PREFIX" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_PROV" "$PUR_BENTO_DIR" "$PUR_BOX_URL_TPL" >/dev/null
    PUR_WS=$(vs_prepare_workspace "$PUR_SUITE_ID" "$PUR_BENTO_PREFIX" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_PROV" "$PUR_CPUS" "$PUR_MEM")
    vs_boot_vm "$PUR_WS" "$PUR_RESOLVED_PROV" "$PUR_OS_FAM"
    vs_ensure_vanilla_snapshot "$PUR_WS" "$PUR_RESOLVED_PROV" "$PUR_OS_FAM" "$PUR_SNAP_NAME" "$PUR_SUITE_JSON"

    # Step 1: Resolve target installer package (GitHub Release or host build)
    PUR_PKG_PATH=$(pr_resolve_artifact "$PUR_SUITE_ID" "$PUR_MANIFEST" "$PUR_RESOLVED_OS" "$PUR_RESOLVED_FMT" "$PUR_PKG_SOURCE" "$PUR_RELEASE_REPO" "$PUR_RELEASE_TAG" "$PUR_ASSET_PAT" "$PUR_BUILD_VAR" "$PUR_FORCE_REBUILD")
    PUR_PKG_SHA=$(pr_compute_sha256 "$PUR_PKG_PATH")

    # Steps 2-5: Execute headless, quick, and custom installs on clean vanilla snapshots + guest UI/browser verify
    PUR_OIFS="$IFS"
    IFS=','
    for PUR_MODE in $PUR_INSTALL_MODES; do
      IFS="$PUR_OIFS"
      PUR_MODE_OUT="${PUR_RESULTS_DIR}/${PUR_RESOLVED_OS}/${PUR_RESOLVED_FMT}/${PUR_MODE}"
      mkdir -p "$PUR_MODE_OUT"
      if [ "$PUR_FORCE_REBUILD" != '1' ] && [ -f "${PUR_MODE_OUT}/result.json" ] && [ -f "${PUR_MODE_OUT}/.pkg_sha256" ] && [ "$(cat "${PUR_MODE_OUT}/.pkg_sha256")" = "$PUR_PKG_SHA" ]; then
        printf '[SKIP] Mode "%s" already passed for artifact SHA-256 %s\n' "$PUR_MODE" "$PUR_PKG_SHA"
      else
        im_execute_mode_trial "$PUR_WS" "$PUR_RESOLVED_PROV" "$PUR_OS_FAM" "$PUR_SNAP_NAME" "$PUR_MODE" "$PUR_RESOLVED_FMT" "$PUR_PKG_PATH" "$PUR_SUITE_JSON" "$PUR_MANIFEST" "$PUR_MODE_OUT"
        printf '%s\n' "$PUR_PKG_SHA" > "${PUR_MODE_OUT}/.pkg_sha256"
      fi
      IFS=','
    done
    IFS="$PUR_OIFS"

    pur_aggregate_metrics "$PUR_PKG_PATH" "$PUR_PKG_SHA" 'converged'
    printf '[OK] Installer-e2e experiment "%s" completed -> %s/metrics.json\n' "$PUR_SUITE_ID" "$PUR_RESULTS_DIR"
    ;;
  *)
    printf '[ERROR] Unsupported pkg_ui_runner phase: %s\n' "$PUR_PHASE" >&2
    exit 1
    ;;
esac
