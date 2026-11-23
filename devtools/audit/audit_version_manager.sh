#!/bin/sh
# ## Overview
# Audits all LibScript components in `_lib/<category>/<component>/` for strict compliance with the Version Manager Contract.
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

VM_WORK=$(libscript_make_tmpdir 'avm')
CAPS_CACHE="${VM_WORK}/CAPS.TSV"
: > "$CAPS_CACHE"
trap 'rm -rf "$VM_WORK"' EXIT INT TERM
ERRORS=0
AUDITED=0

# ## log_vm_violation
# Emits a structured Version Manager Contract violation diagnostic and increments ERRORS.
log_vm_violation() {
  _v_target="$1"
  _v_rule="$2"
  _v_msg="$3"
  printf '[VM CONTRACT VIOLATION] [%s] %s: %s\n' "$_v_rule" "$_v_target" "$_v_msg" >&2
  ERRORS=$((ERRORS + 1))
}

# ## lookup_comp_caps
# Resolves manifest capabilities for a component directory from CAPS_CACHE or jq fallback.
lookup_comp_caps() {
  _lcc_dir="$1"
  _lcc_mf="${_lcc_dir}/manifest.json"
  if [ -s "$CAPS_CACHE" ]; then
    _lcc_hit=$(awk -F '\t' -v p="$_lcc_mf" '$1 == p { print $2; found=1; exit } END { exit(found ? 0 : 1) }' "$CAPS_CACHE" 2>/dev/null || true)
    if [ -n "$_lcc_hit" ]; then
      printf '%s\n' "$_lcc_hit"
      return 0
    fi
  fi
  if [ -f "$_lcc_mf" ] && command -v jq >/dev/null 2>&1; then
    printf ' %s \n' "$(jq -r '.capabilities[]? // empty' "$_lcc_mf" 2>/dev/null | tr '\n' ' ')"
  else
    printf '%s\n' ' userland-package '
  fi
}

# shellcheck disable=SC2329
# ## _vm_content_batch
# Evaluates cli.sh, cli.cmd, setup.sh, setup_generic.sh, env.sh, and env.cmd across a batch of files in one awk pass.
_vm_content_batch() {
  awk -v root="${LIBSCRIPT_ROOT_DIR}/" '
    BEGIN {} function emit_v(t, r, m) {
      print "[VM CONTRACT VIOLATION] [" r "] " t ": " m
      errs++
    }
    BEGIN {} function flush_vm(f,   rel, bn, comp) {
      if (f == "") return
      rel = f
      if (index(rel, root) == 1) rel = substr(rel, length(root) + 1)
      bn = rel; sub(/^.*\//, "", bn)
      comp = rel; sub(/\/[^\/]+$/, "", comp)

      if (bn == "cli.sh") {
        if (!has_comp_core_sh && !has_ls_remote_sh) {
          emit_v(rel, "CLI_ROUTER", "Must delegate to engine/common/component_core.sh or expose mandatory version manager verbs.")
        }
      } else if (bn == "cli.cmd") {
        if (!has_comp_core_cmd && !has_ls_remote_cmd) {
          emit_v(rel, "CLI_ROUTER_WIN", "Must delegate to engine/common/component_core.cmd or expose mandatory version manager verbs.")
        }
      } else if (bn == "setup.sh") {
        if (!has_setup_target) {
          emit_v(rel, "SETUP_DELEGATION", "setup.sh must delegate to engine/common/setup_base.sh or component setup_generic.sh.")
        }
      } else if (bn == "env.cmd") {
        if (has_setlocal && !has_endlocal) {
          emit_v(rel, "ENV_CMD_ENDLOCAL", "env.cmd uses setlocal without endlocal; environment mutations will be lost on return.")
        }
        if (has_bare_env_base && !has_caller_sdir) {
          emit_v(rel, "ENV_BASE_CALLER_CONTEXT", "env.cmd calls env_base.cmd without CALLER_SCRIPT_DIR or explicit component name argument.")
        }
        if (has_bad_path_cmd) {
          emit_v(rel, "NON_IDEMPOTENT_PATH_CMD", "env.cmd prepends to PATH unconditionally; guard with findstr or delegate to env_base.cmd.")
        }
      } else if (bn == "env.sh") {
        if (has_bad_path_sh) {
          emit_v(rel, "NON_IDEMPOTENT_PATH_SH", "env.sh prepends to PATH without idempotency guard; use libscript_path_prepend or a case check.")
        }
      } else if (bn == "setup_generic.sh") {
        if (has_part_prim && comp !~ /^(_lib\/(orchestration|unikernels|kernel|bootloaders|freebsd|illumos|reactos|base-system|virtualization)|synthesis\/disk|infrastructure\/(resources|providers))\//) {
          emit_v(rel, "RECIPE_BOUNDARY", "Tier 1 leaf recipe must not invoke disk/VFS partitioning primitives.")
        }
      }
    }
    FNR == 1 {
      if (prev_f != "") flush_vm(prev_f)
      prev_f = FILENAME
      has_comp_core_sh = 0; has_ls_remote_sh = 0;
      has_comp_core_cmd = 0; has_ls_remote_cmd = 0;
      has_setup_target = 0; has_setlocal = 0; has_endlocal = 0;
      has_bare_env_base = 0; has_caller_sdir = 0;
      has_bad_path_cmd = 0; has_bad_path_sh = 0; has_part_prim = 0;
    }
    {
      sub(/\r$/, "", $0)
      lc = tolower($0)
      if (index($0, "component_core.sh") > 0) has_comp_core_sh = 1
      if (index($0, "ls-remote") > 0) has_ls_remote_sh = 1
      if (index(lc, "component_core.cmd") > 0) has_comp_core_cmd = 1
      if (index(lc, "ls-remote") > 0) has_ls_remote_cmd = 1
      if ($0 ~ /setup_base\.sh|setup_generic\.sh/) has_setup_target = 1
      if (index(lc, "setlocal") > 0) has_setlocal = 1
      if (index(lc, "endlocal") > 0) has_endlocal = 1
      if ($0 ~ /^[[:space:]]*call "%LIBSCRIPT_ROOT_DIR%\\engine\\common\\env_base\.cmd"[[:space:]]*$/) has_bare_env_base = 1
      if (index($0, "CALLER_SCRIPT_DIR") > 0) has_caller_sdir = 1
      if (lc ~ /^[[:space:]]*set[[:space:]]+"?path=[^;]+;%path%"?[[:space:]]*$/) has_bad_path_cmd = 1
      if ($0 ~ /^[[:space:]]*(export[[:space:]]+)?PATH="[^"]+:\$\{?PATH\}?"/) has_bad_path_sh = 1
      if ($0 ~ /^[[:space:]]*(sudo[[:space:]]+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)[[:space:]]/) has_part_prim = 1
    }
    END {
      if (prev_f != "") flush_vm(prev_f)
      exit(errs > 0 ? 1 : 0)
    }
  ' "$@" >&2
}

# ## audit_component_structure
# Audits mandatory files and appends existing lifecycle scripts to the worker content-scan list.
audit_component_structure() {
  _comp_dir="${1%/}"
  _files_out="$2"
  case "$_comp_dir" in
    /*) ;;
    *) _comp_dir="${LIBSCRIPT_ROOT_DIR}/${_comp_dir#./}" ;;
  esac
  [ -d "$_comp_dir" ] || return 0
  case "$_comp_dir" in
    */_common|*/_common/*) return 0 ;;
  esac

  _rel_dir="${_comp_dir#"${LIBSCRIPT_ROOT_DIR}"/}"
  AUDITED=$((AUDITED + 1))

  case "$_rel_dir" in
    _lib/*/*-suite)
      log_vm_violation "$_rel_dir" 'EXP_IN_LIB' 'Empirical campaign suites belong in experiments/<suite-id>/, not inside _lib/.'
      ;;
  esac
  if [ -d "${_comp_dir}/suites" ]; then
    log_vm_violation "$_rel_dir" 'EXP_IN_LIB' "Empirical subsuites belong in experiments/<suite-id>/, not inside ${_rel_dir}/suites/."
  fi

  for _req in cli.sh cli.cmd test.sh test.cmd manifest.json vars.schema.json README.md; do
    if [ ! -f "${_comp_dir}/${_req}" ]; then
      log_vm_violation "$_rel_dir" 'MISSING_CONTRACT_FILE' "Missing required component contract file '${_req}'."
    fi
  done

  _caps_space=$(lookup_comp_caps "$_comp_dir")

  case "$_caps_space" in
    *' userland-package '*|*' sysroot-package '*)
      for _req in setup.sh setup.cmd env.sh env.cmd uninstall.sh uninstall.cmd; do
        if [ ! -f "${_comp_dir}/${_req}" ]; then
          log_vm_violation "$_rel_dir" 'MISSING_CONTRACT_FILE' "Missing required package lifecycle file '${_req}'."
        fi
      done
      case "$_rel_dir" in
        _lib/unikernels/*|_lib/containers/*|_lib/schedulers/*|_lib/iac/*|_lib/virtualization/*) ;;
        *)
          [ -f "${_comp_dir}/cli.sh" ] && printf '%s\n' "${_comp_dir}/cli.sh" >> "$_files_out"
          [ -f "${_comp_dir}/cli.cmd" ] && printf '%s\n' "${_comp_dir}/cli.cmd" >> "$_files_out"
          ;;
      esac
      ;;
  esac

  case "$_caps_space" in
    *' service-daemon '*)
      for _req in service.sh service.cmd; do
        if [ ! -f "${_comp_dir}/${_req}" ]; then
          log_vm_violation "$_rel_dir" 'MISSING_CONTRACT_FILE' "Missing required service-daemon file '${_req}'."
        fi
      done
      ;;
    *)
      for _forbid in service.sh service.cmd; do
        if [ -f "${_comp_dir}/${_forbid}" ]; then
          log_vm_violation "$_rel_dir" 'UNDECLARED_SERVICE_STUB' "Component defines '${_forbid}' without declaring 'service-daemon' capability in manifest.json."
        fi
      done
      ;;
  esac

  for _chk in setup.sh env.cmd env.sh setup_generic.sh; do
    if [ -f "${_comp_dir}/${_chk}" ]; then
      printf '%s\n' "${_comp_dir}/${_chk}" >> "$_files_out"
    fi
  done
}

# shellcheck disable=SC2329
# ## _vm_shard_worker
# Audits a shard of component directories using pure shell stat checks + one batched awk content scan.
_vm_shard_worker() {
  _vsw_shard="$1"
  _vsw_files="${_vsw_shard}.files"
  : > "$_vsw_files"
  ERRORS=0
  AUDITED=0
  while IFS= read -r _vsw_c || [ -n "$_vsw_c" ]; do
    [ -n "$_vsw_c" ] || continue
    audit_component_structure "$_vsw_c" "$_vsw_files"
  done < "$_vsw_shard"
  if [ -s "$_vsw_files" ]; then
    if ! libscript_batch_exec "$_vsw_files" 250 _vm_content_batch; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
  printf '%d %d\n' "$AUDITED" "$ERRORS" > "${_vsw_shard}.cnt"
  [ "$ERRORS" -eq 0 ] && return 0 || return 1
}

# ## audit_no_adhoc_installers
# Verifies that devtools/ and tests/ do not invoke raw OS package managers or git push directly.
audit_no_adhoc_installers() {
  _adhoc_list="${VM_WORK}/ADHOC.TXT"
  : > "$_adhoc_list"
  set +f
  for _dir in "${LIBSCRIPT_ROOT_DIR}/devtools" "${LIBSCRIPT_ROOT_DIR}/tests"; do
    [ -d "$_dir" ] || continue
    for _script in "$_dir"/*.sh "$_dir"/*.cmd "$_dir"/*.ps1; do
      [ -f "$_script" ] || continue
      _rel="${_script#"${LIBSCRIPT_ROOT_DIR}"/}"
      case "$_rel" in
        *audit*|*test_vm_contract*|*distro_pkg_roundtrip*) continue ;;
      esac
      printf '%s\n' "$_script" >> "$_adhoc_list"
    done
  done
  set -f
  if [ -s "$_adhoc_list" ]; then
    if ! libscript_batch_exec "$_adhoc_list" 250 _vm_adhoc_batch; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

# shellcheck disable=SC2329
# ## _vm_adhoc_batch
# Checks a batch of devtools/ and tests/ scripts for adhoc winget/choco and git push calls.
_vm_adhoc_batch() {
  awk -v root="${LIBSCRIPT_ROOT_DIR}/" '
    FNR == 1 {
      rel = FILENAME
      if (index(rel, root) == 1) rel = substr(rel, length(root) + 1)
      seen_pkg = 0; seen_push = 0
    }
    !seen_pkg && /^[[:space:]]*(winget[[:space:]]+install|choco[[:space:]]+install)[[:space:]]/ {
      seen_pkg = 1
      print "[VM CONTRACT VIOLATION] [ADHOC_INSTALLER] " rel ": Direct winget/choco invocation in devtools/ or tests/ is prohibited; use LibScript components."
      errs++
    }
    !seen_push && /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/ {
      seen_push = 1
      print "[VM CONTRACT VIOLATION] [REMOTE_SAFETY] " rel ": Strict safety violation: \x27git push\x27 is prohibited."
      errs++
    }
    END { exit(errs > 0 ? 1 : 0) }
  ' "$@" >&2
}

printf '=== LibScript Version Manager Contract Audit ===\n'

if [ "$#" -gt 0 ]; then
  _exp_files="${VM_WORK}/EXP_FILES.TXT"
  : > "$_exp_files"
  for _arg in "$@"; do
    audit_component_structure "$_arg" "$_exp_files"
  done
  if [ -s "$_exp_files" ]; then
    if ! libscript_batch_exec "$_exp_files" 250 _vm_content_batch; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
else
  _comps_file="${VM_WORK}/COMPS.TXT"
  : > "$_comps_file"
  set +f
  for _cat_d in "${LIBSCRIPT_ROOT_DIR}/_lib"/*; do
    [ -d "$_cat_d" ] || continue
    for _cmp_d in "$_cat_d"/*; do
      [ -d "$_cmp_d" ] || continue
      printf '%s\n' "$_cmp_d" >> "$_comps_file"
    done
  done
  set -f

  if command -v jq >/dev/null 2>&1 && [ -d "${LIBSCRIPT_ROOT_DIR}/_lib" ]; then
    find "${LIBSCRIPT_ROOT_DIR}/_lib" -type f -name 'manifest.json' -exec jq -r '
      "\(input_filename)\t \([.capabilities[]? // empty] | join(" ")) "
    ' {} + > "$CAPS_CACHE" 2>/dev/null || true
  fi

  _sh_dir="${VM_WORK}/shards"
  mkdir -p "$_sh_dir"
  _jobs=$(libscript_parallel_jobs)
  if [ "$_jobs" -gt 1 ]; then
    awk -v n="$_jobs" -v d="$_sh_dir" 'NF > 0 { idx = (c % n) + 1; c++; out = d "/S" idx ".TXT"; print $0 >> out; close(out) }' "$_comps_file"
    _pids=''
    _i=1
    while [ "$_i" -le "$_jobs" ]; do
      if [ -s "${_sh_dir}/S${_i}.TXT" ]; then
        ( _vm_shard_worker "${_sh_dir}/S${_i}.TXT" ) &
        _pids="${_pids} $!"
      fi
      _i=$((_i + 1))
    done
    for _p in $_pids; do
      wait "$_p" || true
    done
    set +f
    _sum_aud=0
    _sum_err=0
    for _cf in "${_sh_dir}"/*.cnt; do
      [ -f "$_cf" ] || continue
      read -r _ca _ce < "$_cf"
      _sum_aud=$((_sum_aud + _ca))
      _sum_err=$((_sum_err + _ce))
    done
    set -f
    AUDITED="$_sum_aud"
    ERRORS="$_sum_err"
  else
    _vm_shard_worker "$_comps_file" || true
    read -r AUDITED ERRORS < "${_comps_file}.cnt"
  fi
  audit_no_adhoc_installers
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[FAIL] Version Manager Contract Audit failed with %d violation(s) across %d components.\n' "$ERRORS" "$AUDITED" >&2
  exit 1
fi

printf '[PASS] All %d components strictly adhere to the LibScript Version Manager Contract!\n' "$AUDITED"
exit 0
