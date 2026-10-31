#!/bin/sh
# ## Overview
# Audits all LibScript components in `_lib/<category>/<component>/` for strict compliance with the Version Manager Contract.
#
# ## Usage
# ./devtools/audit/audit_version_manager.sh [component_dir ...]

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
  if [ -f "${_comp_dir}/setup.cmd" ]; then
    if ! grep -Eiq "setup_base\.cmd|setup_generic\.cmd" "${_comp_dir}/setup.cmd"; then
      log_vm_violation "${_rel_dir}/setup.cmd" "SETUP_DELEGATION_WIN" "Must call or delegate to _lib\\_common\\setup_base.cmd (or setup_generic.cmd)."
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
    if grep -Eiq '^[[:space:]]*set[[:space:]]+"?PATH=[^;]+;%PATH%"?[[:space:]]*$' "${_comp_dir}/env.cmd"; then
      log_vm_violation "${_rel_dir}/env.cmd" "NON_IDEMPOTENT_PATH_CMD" "env.cmd prepends to PATH unconditionally; guard with findstr or delegate to env_base.cmd."
    fi
  fi
  if [ -f "${_comp_dir}/env.sh" ]; then
    if grep -Eq '^[[:space:]]*(export[[:space:]]+)?PATH="[^"]+:\$\{?PATH\}?"' "${_comp_dir}/env.sh"; then
      log_vm_violation "${_rel_dir}/env.sh" "NON_IDEMPOTENT_PATH_SH" "env.sh prepends to PATH without idempotency guard; use libscript_path_prepend or a case check."
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

  # 5. Ban raw winget/choco/scoop and raw network calls in Tier 1 leaf recipes (must delegate to _lib/_common/pkg_mgr.*)
  case "$_rel_dir" in
    _lib/package-managers/*)
      ;;
    *)
      for _cmd_file in "$_comp_dir"/setup*.cmd "$_comp_dir"/uninstall*.cmd; do
        [ -f "$_cmd_file" ] || continue
        if grep -Eiq '^[ 	]*(where[ 	]+(winget|choco|scoop).*&&[ 	]*)?(call[ 	]+)?(winget|choco|scoop)[ 	]+(install|uninstall|upgrade|update)([ 	]|$)' "$_cmd_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_cmd_file")" "RAW_PACKAGE_MANAGER" "Direct winget/choco/scoop install/uninstall in $(basename "$_cmd_file"); delegate to pkg_mgr.cmd."
        fi
        if grep -Eiq '(Invoke-WebRequest|Invoke-RestMethod|[ 	"]iwr[ 	]|[ 	"]irm[ 	]|certutil[ 	]+-urlcache)' "$_cmd_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_cmd_file")" "RAW_NETWORK_FETCH" "Raw network fetch in $(basename "$_cmd_file"); delegate to pkg_mgr.cmd."
        fi
      done
      for _ps1_file in "$_comp_dir"/setup*.ps1 "$_comp_dir"/uninstall*.ps1; do
        [ -f "$_ps1_file" ] || continue
        if grep -Eiq '^[ 	]*(&[ 	]+)?(winget|choco|scoop)[ 	]+(install|uninstall|upgrade|update)([ 	]|$)' "$_ps1_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_ps1_file")" "RAW_PACKAGE_MANAGER" "Direct winget/choco/scoop install/uninstall in $(basename "$_ps1_file"); delegate to pkg_mgr.ps1."
        fi
        if grep -Eiq '^[ 	]*[^#]*(Invoke-WebRequest|Invoke-RestMethod|\biwr\b|\birm\b)' "$_ps1_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_ps1_file")" "RAW_NETWORK_FETCH" "Raw Invoke-WebRequest/Invoke-RestMethod in $(basename "$_ps1_file"); delegate to pkg_mgr.ps1."
        fi
      done
      ;;
  esac

  # 6. Ban raw apt-get/brew/dnf/apk/pkg install/remove, brew services, and raw curl/wget/aria2c in Tier 1 leaf recipes (must delegate to pkg_mgr.sh)
  case "$_rel_dir" in
    _lib/package-managers/*)
      for _sh_file in "$_comp_dir"/setup*.sh "$_comp_dir"/install*.sh; do
        [ -f "$_sh_file" ] || continue
        if grep -Eq '^[ 	]*[^#]*(curl[ 	]+-[a-zA-Z0-9#-]*[sSfLOo]|wget[ 	]+-[a-zA-Z0-9-]*[qO]|aria2c[ 	]+-[dox])' "$_sh_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_sh_file")" "RAW_NETWORK_FETCH" "Raw curl/wget/aria2c in $(basename "$_sh_file"); delegate to libscript_fetch_stdout or libscript_download."
        fi
      done
      ;;
    *)
      for _sh_file in "$_comp_dir"/setup*.sh "$_comp_dir"/uninstall*.sh; do
        [ -f "$_sh_file" ] || continue
        if grep -Eq '^[ 	]*[^#]*(priv[ 	]+|sudo[ 	]+)?(apt-get[ 	]+(install|remove|purge)|apt[ 	]+(install|remove|purge)|brew[ 	]+(install|uninstall|services)|dnf[ 	]+(install|remove)|yum[ 	]+(install|remove)|apk[ 	]+(add|del)|pacman[ 	]+(-S|-R)|zypper[ 	]+(install|remove)|pkg[ 	]+(install|delete))[ 	]' "$_sh_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_sh_file")" "RAW_PACKAGE_MANAGER" "Direct OS package manager call in $(basename "$_sh_file"); delegate to _lib/_common/pkg_mgr.sh or _lib/_common/service.sh."
        fi
        if grep -Eq '^[ 	]*[^#]*(curl[ 	]+-[a-zA-Z0-9#-]*[sSfLOo]|wget[ 	]+-[a-zA-Z0-9-]*[qO]|aria2c[ 	]+-[dox])' "$_sh_file" && ! grep -Eq '(--unix-socket|libscript-allow-raw-)' "$_sh_file"; then
          log_vm_violation "${_rel_dir}/$(basename "$_sh_file")" "RAW_NETWORK_FETCH" "Raw curl/wget/aria2c in $(basename "$_sh_file"); delegate to libscript_fetch_stdout or libscript_download."
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
