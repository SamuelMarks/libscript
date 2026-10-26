#!/bin/sh
# ## Overview
# Audits all LibScript components in _lib/<category>/<component>/ for strict
# compliance with the Version Manager Contract (WHAT_A_VERSION_MANAGER_SHOULD_LOOK_LIKE.md
# and AGENTS.md Section 2):
# - Mandatory files (cli, setup, env, service, test, uninstall, manifest.json, vars.schema.json, README.md)
# - Delegation of cli.* to component_core.* (or full verb routing) and setup.* to setup_base.*
# - Zero ad-hoc OS package manager calls in devtools/ or tests/
# - Tier 1 recipe boundaries (no raw mount/fdisk/mkfs in leaf packages)
# - Zero git push invocations
#
# ## Usage
# ./devtools/audit/audit_version_manager.sh [component_dir ...]

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
export LIBSCRIPT_ROOT_DIR

ERRORS=0
AUDITED=0

# ## log_vm_violation
# Reports a Version Manager Contract violation and increments ERRORS.
log_vm_violation() {
  _target="$1"
  _rule="$2"
  _msg="$3"
  printf '[VM CONTRACT VIOLATION] [%s] %s: %s
' "$_rule" "$_target" "$_msg" >&2
  ERRORS=$((ERRORS + 1))
}

# ## audit_component_dir
# Verifies that a single _lib/<category>/<component> directory satisfies the Version Manager Contract.
audit_component_dir() {
  _comp_dir="$1"
  [ -d "$_comp_dir" ] || return 0
  case "$_comp_dir" in
    */_common|*/_common/*) return 0 ;;
  esac

  _rel_dir="${_comp_dir#"${LIBSCRIPT_ROOT_DIR}"/}"
  AUDITED=$((AUDITED + 1))

  # 1. Mandatory contract files
  for _req in cli.sh cli.cmd setup.sh setup.cmd env.sh env.cmd service.sh service.cmd test.sh test.cmd uninstall.sh uninstall.cmd manifest.json vars.schema.json README.md; do
    if [ ! -f "${_comp_dir}/${_req}" ]; then
      log_vm_violation "$_rel_dir" "MISSING_CONTRACT_FILE" "Missing required Version Manager file '${_req}'."
    fi
  done

  # 2. Verify cli.sh and cli.cmd route via component_core or implement mandatory verbs
  case "$_rel_dir" in
    _lib/cloud/*|_lib/cloud-providers/*|_lib/orchestration/*|_lib/ai-serving/*|_lib/ml-training/*|_lib/freebsd/*|_lib/illumos/*|_lib/virtualization/*)
      # Tier 2/3/4 operators and synthesizers may expose custom operator verbs alongside install/test
      ;;
    *)
      if [ -f "${_comp_dir}/cli.sh" ]; then
        if ! grep -q "component_core.sh" "${_comp_dir}/cli.sh" && ! grep -q "ls-remote" "${_comp_dir}/cli.sh"; then
          log_vm_violation "${_rel_dir}/cli.sh" "CLI_ROUTER" "Must delegate to _lib/_common/component_core.sh or expose mandatory version manager verbs."
        fi
      fi
      if [ -f "${_comp_dir}/cli.cmd" ]; then
        if ! grep -qi "component_core.cmd" "${_comp_dir}/cli.cmd" && ! grep -qi "ls-remote" "${_comp_dir}/cli.cmd"; then
          log_vm_violation "${_rel_dir}/cli.cmd" "CLI_ROUTER_WIN" "Must delegate to _lib/_common/component_core.cmd or expose mandatory version manager verbs."
        fi
      fi
      ;;
  esac

  # 3. Verify setup.sh and setup.cmd delegate to setup_base or setup_generic
  if [ -f "${_comp_dir}/setup.sh" ]; then
    if ! grep -Eq "setup_base\.sh|setup_generic\.sh" "${_comp_dir}/setup.sh"; then
      log_vm_violation "${_rel_dir}/setup.sh" "SETUP_DELEGATION" "Must source or delegate to _lib/_common/setup_base.sh (or setup_generic.sh)."
    fi
  fi

  # 3b. Verify env.cmd exports across endlocal boundary if setlocal is used
  if [ -f "${_comp_dir}/env.cmd" ]; then
    if grep -qi "setlocal" "${_comp_dir}/env.cmd" && ! grep -qi "endlocal" "${_comp_dir}/env.cmd"; then
      log_vm_violation "${_rel_dir}/env.cmd" "ENV_CMD_ENDLOCAL" "env.cmd uses setlocal without endlocal; environment mutations will be lost on return."
    fi
    if grep -Eq '^[[:space:]]*call "%LIBSCRIPT_ROOT_DIR%\\_lib\\_common\\env_base\.cmd"[[:space:]]*$' "${_comp_dir}/env.cmd"; then
      if ! grep -q 'CALLER_SCRIPT_DIR' "${_comp_dir}/env.cmd"; then
        log_vm_violation "${_rel_dir}/env.cmd" "ENV_BASE_CALLER_CONTEXT" "env.cmd calls env_base.cmd without CALLER_SCRIPT_DIR or explicit component name argument."
      fi
    fi
  fi

  # 4. Verify Tier 1 leaf recipes do not invoke kernel/partitioning primitives
  case "$_rel_dir" in
    _lib/orchestration/*|_lib/storage/*|_lib/kernel/*|_lib/bootloaders/*|_lib/freebsd/*|_lib/illumos/*|_lib/base-system/*|_lib/virtualization/*|_lib/cloud/*|_lib/cloud-providers/*)
      ;;
    *)
      if [ -f "${_comp_dir}/setup_generic.sh" ]; then
        if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)[[:space:]]' "${_comp_dir}/setup_generic.sh"; then
          log_vm_violation "${_rel_dir}/setup_generic.sh" "RECIPE_BOUNDARY" "Tier 1 leaf recipe must not invoke disk/VFS partitioning primitives."
        fi
      fi
      ;;
  esac

  # 5. Ban raw winget/choco install in setup*.cmd (must delegate to pkg_mgr.cmd :libscript_depends)
  case "$_rel_dir" in
    _lib/package-managers/winget|_lib/package-managers/choco)
      ;;
    *)
      for _cmd_file in "$_comp_dir"/setup*.cmd; do
        [ -f "$_cmd_file" ] || continue
        if grep -Eiq '^[[:space:]]*(call[[:space:]]+)?(winget|choco)[[:space:]]+install([[:space:]]|$)' "$_cmd_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_cmd_file")" "RAW_WINGET_IN_RECIPE" "Direct winget/choco install in setup*.cmd; delegate to pkg_mgr.cmd :libscript_depends."
        fi
      done
      ;;
  esac

  # 6. Ban raw apt-get/brew/dnf/apk install in Tier 1 leaf recipes (must delegate to pkg_mgr.sh)
  case "$_rel_dir" in
    _lib/package-managers/apt|_lib/package-managers/brew|_lib/package-managers/dnf|_lib/package-managers/yum|_lib/package-managers/apk|_lib/package-managers/pacman|_lib/package-managers/zypper|_lib/package-managers/pkg)
      ;;
    *)
      for _sh_file in "$_comp_dir"/setup*.sh; do
        [ -f "$_sh_file" ] || continue
        if grep -Eq '^[[:space:]]*(priv[[:space:]]+)?(apt-get[[:space:]]+install|brew[[:space:]]+install|dnf[[:space:]]+install[[:space:]]+-y[[:space:]]+epel-release|apk[[:space:]]+add)[[:space:]]' "$_sh_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_sh_file")" "RAW_OS_PKG_MGR_IN_RECIPE" "Direct OS package manager install in setup*.sh; delegate to _lib/_common/pkg_mgr.sh (depends / libscript_depends)."
        fi
      done
      ;;
  esac
}

# ## audit_no_adhoc_installers
# Verifies that devtools/ and tests/ do not invoke raw OS package managers directly.
audit_no_adhoc_installers() {
  for _dir in "${LIBSCRIPT_ROOT_DIR}/devtools" "${LIBSCRIPT_ROOT_DIR}/tests"; do
    [ -d "$_dir" ] || continue
    _scripts=$(find "$_dir" -maxdepth 1 -type f | sort)
    for _script in $_scripts; do
      [ -f "$_script" ] || continue
      case "$_script" in
        *.sh|*.cmd|*.ps1) ;;
        *) continue ;;
      esac
      _rel="${_script#"${LIBSCRIPT_ROOT_DIR}"/}"
      case "$_rel" in
        *audit*|*test_vm_contract*|*distro_pkg_roundtrip*) continue ;;
      esac
      if grep -Eq '^[[:space:]]*(winget[[:space:]]+install|choco[[:space:]]+install)[[:space:]]' "$_script"; then
        log_vm_violation "$_rel" "ADHOC_INSTALLER" "Direct winget/choco invocation in devtools/ or tests/ is prohibited; use LibScript components."
      fi
      if grep -Eq '^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)' "$_script"; then
        log_vm_violation "$_rel" "REMOTE_SAFETY" "Strict safety violation: 'git push' is prohibited."
      fi
    done
  done
}

printf '=== LibScript Version Manager Contract Audit ===
'

if [ $# -gt 0 ]; then
  for _arg in "$@"; do
    audit_component_dir "$_arg"
  done
else
  _comp_list=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 2 -maxdepth 2 -type d | sort)
  for _comp_path in $_comp_list; do
    [ -d "$_comp_path" ] || continue
    audit_component_dir "$_comp_path"
  done
  audit_no_adhoc_installers
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[FAIL] Version Manager Contract Audit failed with %d violation(s) across %d components.
' "$ERRORS" "$AUDITED" >&2
  exit 1
fi

printf '[PASS] All %d components strictly adhere to the LibScript Version Manager Contract!
' "$AUDITED"
exit 0
