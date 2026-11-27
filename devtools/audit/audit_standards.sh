#!/bin/sh
# ## Overview
# Audits codebase and staged files for adherence to LibScript engineering standards: - POSIX /bin/sh usage and canonical THIS_FILE preamble - Windows batch script parity (.cmd / .bat) - No evil eval usage - Idempotency patterns - 100% doc block coverage (## Overview and ## Usage)
# ## Usage
# Execute this script to audit files: ./devtools/audit/audit_standards.sh [--all | --staged | <file>...]
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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

SCRIPT_NAME="${REPO_ROOT}/engine/common/parallel.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

# ## show_help
# Displays usage and help information for the audit tool.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [--all | --staged | <file>...]"
  printf '%s\n' 'Audits files for adherence to LibScript engineering standards.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --all               Audit all tracked script files in repository.'
  printf '%s\n' '  --staged            Audit git-staged files (default if no files given).'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
}

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ] || [ "${1:-}" = '/?' ] || [ "${1:-}" = '-?' ]; then
  show_help
  exit 0
fi

ORIG_PWD=$(pwd)
cd "$REPO_ROOT"

AS_ERR_DIR=$(libscript_make_tmpdir 'as_err')
AS_ERR_LOG="${AS_ERR_DIR}/VIOLATIONS.TXT"
: > "$AS_ERR_LOG"
export AS_ERR_LOG
trap 'rm -rf "$AS_ERR_DIR"; trap - INT TERM HUP EXIT; exit 130' INT TERM HUP

ERRORS=0

# ## log_failure
# Records and outputs an audit violation message.
log_failure() {
  target_file="$1"
  rule_name="$2"
  details="$3"
  printf '[STANDARDS VIOLATION] [%s] %s: %s\n' "$rule_name" "$target_file" "$details" >&2
  ERRORS=$((ERRORS + 1))
  if [ -n "${AS_ERR_LOG:-}" ]; then
    printf '1\n' >> "$AS_ERR_LOG"
  fi
}

# shellcheck disable=SC2329
# ## is_excluded_path
# Checks whether a given path should be skipped from audits.
is_excluded_path() {
  check_path="$1"
  case "$check_path" in
    .git/*|*/.git/*|gen/*|*/gen/*|cache/*|*/cache/*|tmp/*|*/tmp/*|tests_tmp/*|*/tests_tmp/*|node_modules/*|*/node_modules/*|*/.vagrant/*|.vagrant/*|.venv/*|*/.venv/*|venv/*|*/venv/*|dist/*|*/dist/*|build/*|*/build/*|.angular/*|*/.angular/*|.gradle/*|*/.gradle/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# shellcheck disable=SC2329
# ## report_sh_violation
# Applies file-level allowlists for POSIX shell violations and records remaining failures.
report_sh_violation() {
  file="$1"
  v_rule="$2"
  v_msg="$3"
  case "$v_rule" in
    MISSING_SHEBANG)
      case "$file" in
        *.tpl|*.template) ;;
        *) log_failure "$file" 'POSIX_SHEBANG' "$v_msg" ;;
      esac
      ;;
    THIS_FILE_DANCE|RECURSION_GUARD|ROOT_DIR_RESOLUTION|ZSH_SHELLCHECK_TAG)
      case "$file" in
        *Dockerfile*|*.tpl) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_PACKAGE_MANAGER)
      case "$file" in
        *engine/common/pkg_mgr.sh|*engine/common/service.sh|*_lib/package-managers/*|*synthesis/distro/linux/*|*tests/*|*devtools/ci/*|*devtools/audit/*|*docker*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_DAEMON_MANAGER)
      case "$file" in
        *engine/common/service.sh|*engine/common/service_install.sh|*engine/common/logs_service.sh|*engine/common/os_info.sh|*engine/common/daemonize.sh|*_lib/init-systems/*|*workloads/schedulers/*|*devtools/audit/*|*.tpl) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_NETWORK_FETCH)
      case "$file" in
        *engine/common/pkg_mgr.sh|*engine/common/daemonize.sh|*_lib/utilities/curl/test.sh|*_lib/utilities/wget/test.sh|*_lib/utilities/aria2/test.sh|*workloads/apps/*/test_harness.sh|*workloads/apps/*/health*.sh|*workloads/apps/*/service.sh|*tests/*|*devtools/ci/*|*devtools/capture_*|*devtools/render_*|*devtools/verify_*|*devtools/wait_*|*devtools/trigger_*|*docker*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_REMOTE_SYNC)
      case "$file" in
        *engine/common/remote_sync.sh|*_lib/utilities/rsync/*|*_lib/utilities/openssh/*|*synthesis/msi/*|*devtools/*|*tests/*|*vagrant/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_PYTHON_VENV)
      case "$file" in
        *engine/common/python_env.sh|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_PRIV_ESCALATION)
      case "$file" in
        *engine/common/priv.sh|*_lib/base-system/sudo/*|*devtools/*|*tests/*|*vagrant/*|*synthesis/msi/*|*workloads/services/*|*infrastructure/cli_actions/*|cli/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_ENVSUBST)
      case "$file" in
        *engine/common/envsubst_safe.sh|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_UUID_GEN)
      case "$file" in
        *engine/common/uuid_gen.sh|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_HW_DETECT)
      case "$file" in
        *engine/common/hw_tune.sh|*engine/common/source_builder.sh|*devtools/*|*tests/*|*synthesis/msi/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    EXTERNAL_VERSION_MANAGER)
      case "$file" in
        *engine/common/versioning.sh|*_lib/package-managers/*|*_lib/languages/rust/*|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_UNAME)
      case "$file" in
        *engine/common/os_info.sh|*devtools/*|*tests/*|*vagrant/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_GCLOUD_TPU)
      case "$file" in
        *infrastructure/providers/gcp*|*infrastructure/resources/core/tags.sh|*engine/common/tfrc_guard.sh|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    UNNECESSARY_DOUBLE_QUOTES|SC2015_AND_OR|IDEMPOTENCY)
      case "$file" in
        *audit_posix.sh|*audit_standards.sh|*.tpl) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    *)
      log_failure "$file" "$v_rule" "$v_msg"
      ;;
  esac
}

# shellcheck disable=SC2329
# ## report_ps1_violation
# Applies file-level allowlists for PowerShell violations and records remaining failures.
report_ps1_violation() {
  file="$1"
  v_rule="$2"
  v_msg="$3"
  case "$v_rule" in
    RAW_NETWORK_FETCH)
      case "$file" in
        *engine/common/pkg_mgr.ps1|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_PACKAGE_MANAGER)
      case "$file" in
        *engine/common/pkg_mgr.ps1|*_lib/package-managers/*|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_DAEMON_MANAGER)
      case "$file" in
        *engine/common/service.ps1|*engine/common/service_install.ps1|*engine/common/daemonize.ps1|*_lib/init-systems/*|*devtools/audit/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    *)
      log_failure "$file" "$v_rule" "$v_msg"
      ;;
  esac
}

# shellcheck disable=SC2329
# ## report_cmd_violation
# Applies file-level allowlists for Windows Batch violations and records remaining failures.
report_cmd_violation() {
  file="$1"
  v_rule="$2"
  v_msg="$3"
  case "$v_rule" in
    CMD_ROOT_DIR_RESOLUTION)
      case "$file" in
        /tmp/*|*/tmp/*|*/Temp/*|*/temp/*|*/var/folders/*|*tests_tmp/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_NETWORK_FETCH)
      case "$file" in
        *engine/common/pkg_mgr.cmd|*engine/common/daemonize.cmd|*_lib/utilities/curl/test.cmd|*_lib/utilities/wget/test.cmd|*_lib/utilities/aria2/test.cmd|*devtools/*|*tests/*|synthesis/formats/docker_compose.cmd) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_PACKAGE_MANAGER)
      case "$file" in
        *engine/common/pkg_mgr.cmd|*_lib/package-managers/*|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_DAEMON_MANAGER)
      case "$file" in
        *engine/common/service.cmd|*engine/common/service_install.cmd|*engine/common/daemonize.cmd|*_lib/init-systems/*|*workloads/schedulers/*|*devtools/audit/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_REMOTE_SYNC)
      case "$file" in
        *engine/common/remote_sync.cmd|*_lib/utilities/rsync/*|*_lib/utilities/openssh/*|*synthesis/msi/*|*devtools/*|*tests/*|*vagrant/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_PYTHON_VENV)
      case "$file" in
        *engine/common/python_env.cmd|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    RAW_UUID_GEN)
      case "$file" in
        *engine/common/uuid_gen.cmd|*devtools/*|*tests/*) ;;
        *) log_failure "$file" "$v_rule" "$v_msg" ;;
      esac
      ;;
    *)
      log_failure "$file" "$v_rule" "$v_msg"
      ;;
  esac
}

# shellcheck disable=SC2329
# ## audit_sh_batch
# Evaluates a batch of POSIX .sh files in a single multi-file awk pass plus companion parity checks.
audit_sh_batch() {
  [ "$#" -gt 0 ] || return 0
  for _asb_f in "$@"; do
    case "$_asb_f" in
      .githooks/pre-commit|*/.githooks/pre-commit|dockerfiles-ssh/*|*.tpl|*Vagrantfile*) ;;
      *)
        _asb_cmd="${_asb_f%.sh}.cmd"
        _asb_bat="${_asb_f%.sh}.bat"
        if [ ! -f "$_asb_cmd" ] && [ ! -f "$_asb_bat" ]; then
          log_failure "$_asb_f" 'WINDOWS_PARITY' "Missing Windows batch equivalent file ('$_asb_cmd')."
        fi
        ;;
    esac
  done

  _sh_out=$(awk '
    BEGIN {} function reset_sh() {
      in_heredoc = 0; heredoc_quoted = 0; delim = ""; shebang_count = 0; shebang_lines = ""; first_line = "";
      has_this_file = 0; has_stack = 0; has_root_dir = 0; has_zsh_sc = 0;
      has_overview = 0; has_usage = 0; has_set_feu = 0; has_crlf = 0;
      mkdir_hits = ""; ln_hits = ""; eval_hits = ""; git_push_hits = ""; raw_daemon_hits = "";
      adhoc_pkg_hits = ""; raw_fetch_hits = "";
      raw_sync_hits = ""; raw_venv_hits = ""; raw_priv_hits = ""; raw_envsubst_hits = "";
      raw_uuid_hits = ""; raw_hw_hits = ""; ext_vm_hits = ""; raw_uname_hits = "";
      raw_tpu_hits = ""; placeholder_doc_hits = ""; bad_stack_quote_hits = "";
      unreachable_stack_hits = ""; unguarded_src_hits = ""; unnecessary_dq_hits = "";
      sc2015_hits = ""; saw_top_ret_nr = 0; last_script_name_nr = 0;
      allow_pkg_next = 0; allow_fetch_next = 0; allow_daemon_next = 0;
      allow_sync_next = 0; allow_venv_next = 0; allow_priv_next = 0; allow_envsubst_next = 0;
      allow_uuid_next = 0; allow_hw_next = 0; allow_extvm_next = 0; allow_uname_next = 0;
      boundary_hits = ""; venv_leak_hits = ""; unguarded_sh_path = "";
      interp_hits = ""; leak_hits = ""; commented_dep_hits = "";
      has_stack_pop = 0; has_bare_home = 0;
      self_exec_dollar0_hits = ""; unzip_no_o_hits = ""; libscript_home_bare_hits = "";
      dash_return_probe_hits = "";
    }
    BEGIN {} function emit(f, r, m) {
      print f "|" r "|" m
    }
    BEGIN {} function flush_sh(f) {
      if (f == "") return
      if (has_crlf) emit(f, "POSIX_EOL_LF", "Literal carriage return (CRLF) detected in POSIX shell script; enforce LF line endings.")
      if (first_line ~ /bash|zsh|ksh/) {
        emit(f, "POSIX_SHEBANG", "Non-POSIX shebang found: " first_line ". LibScript requires #!/bin/sh.")
      } else if (first_line !~ /^#!\/bin\/sh/) {
        emit(f, "MISSING_SHEBANG", "Missing #!/bin/sh shebang on line 1.")
      }
      if (shebang_count > 1) emit(f, "DUPLICATE_SHEBANG", "Multiple shebangs found outside of heredocs at lines: " shebang_lines ".")
      if (!has_set_feu) emit(f, "SET_FEU_SAFETY", "Missing set -feu in first 38 lines.")
      if (!has_this_file) emit(f, "THIS_FILE_DANCE", "Missing canonical THIS_FILE= resolution in first 30 lines.")
      if (!has_stack) emit(f, "RECURSION_GUARD", "Missing STACK recursion guard in first 35 lines.")
      if (!has_root_dir) emit(f, "ROOT_DIR_RESOLUTION", "Missing LIBSCRIPT_ROOT_DIR resolution in header.")
      if (!has_zsh_sc) emit(f, "ZSH_SHELLCHECK_TAG", "Missing # shellcheck disable=SC2296 in ZSH_VERSION header block.")
      if (!has_overview) emit(f, "DOC_OVERVIEW", "Missing doc block ## Overview in first 30 lines.")
      if (!has_usage) emit(f, "DOC_USAGE", "Missing doc block ## Usage in first 30 lines.")
      if (placeholder_doc_hits != "") emit(f, "DOC_PLACEHOLDER", "Auto-generated placeholder docstring found: " placeholder_doc_hits)
      if (mkdir_hits != "") emit(f, "IDEMPOTENCY", "Unguarded mkdir found without -p: " mkdir_hits)
      if (ln_hits != "") emit(f, "IDEMPOTENCY", "Unguarded ln -s found without -f: " ln_hits)
      if (eval_hits != "") emit(f, "BAN_EVAL", "Disallowed use of eval found: " eval_hits)
      if (f !~ /audit_standards\.sh$/ && dash_return_probe_hits != "") emit(f, "DASH_UNSAFE_RETURN_PROBE", "Unsafe negated (return 0) CLI probe found (top-level return 0 succeeds in POSIX dash): " dash_return_probe_hits)
      if (git_push_hits != "") emit(f, "REMOTE_SAFETY", "Strict safety violation: found git push invocation: " git_push_hits)
      if (adhoc_pkg_hits != "") emit(f, "RAW_PACKAGE_MANAGER", "Raw package manager usage found (delegate to pkg_mgr.sh / libscript_depends): " adhoc_pkg_hits)
      if (raw_daemon_hits != "") emit(f, "RAW_DAEMON_MANAGER", "Raw init/daemon manager usage found (delegate to engine/common/service.sh or service_install.sh): " raw_daemon_hits)
      if (raw_fetch_hits != "") emit(f, "RAW_NETWORK_FETCH", "Raw curl/wget/aria2c network call found (delegate to libscript_download or libscript_fetch_stdout): " raw_fetch_hits)
      if (raw_sync_hits != "") emit(f, "RAW_REMOTE_SYNC", "Raw rsync/scp call found (delegate to engine/common/remote_sync.sh): " raw_sync_hits)
      if (raw_venv_hits != "") emit(f, "RAW_PYTHON_VENV", "Explicit Python venv creation found (delegate to engine/common/python_env.sh): " raw_venv_hits)
      if (raw_priv_hits != "") emit(f, "RAW_PRIV_ESCALATION", "Raw sudo invocation found (delegate to priv / priv_as from engine/common/priv.sh): " raw_priv_hits)
      if (raw_envsubst_hits != "") emit(f, "RAW_ENVSUBST", "Raw envsubst invocation found (delegate to envsubst_safe from engine/common/envsubst_safe.sh): " raw_envsubst_hits)
      if (raw_uuid_hits != "") emit(f, "RAW_UUID_GEN", "Non-deterministic UUID generation found (delegate to engine/common/uuid_gen.sh): " raw_uuid_hits)
      if (raw_hw_hits != "") emit(f, "RAW_HW_DETECT", "Raw hardware core/RAM query found (delegate to engine/common/hw_tune.sh): " raw_hw_hits)
      if (ext_vm_hits != "") emit(f, "EXTERNAL_VERSION_MANAGER", "Direct third-party version manager invocation found (delegate to LibScript native components): " ext_vm_hits)
      if (raw_uname_hits != "") emit(f, "RAW_UNAME", "Raw uname invocation found (use pre-evaluated UNAME, UNAME_LOWER, ARCH, or KERNEL_RELEASE from engine/common/os_info.sh): " raw_uname_hits)
      if (raw_tpu_hits != "") emit(f, "RAW_GCLOUD_TPU", "Ad-hoc gcloud compute tpus tpu-vm call found (delegate to infrastructure/providers/gcp-tpu-vm): " raw_tpu_hits)
      if (unguarded_src_hits != "") emit(f, "UNGUARDED_SOURCE_SH", "Sourcing LibScript .sh file without setting SCRIPT_NAME first: " unguarded_src_hits)
      if (unnecessary_dq_hits != "") emit(f, "UNNECESSARY_DOUBLE_QUOTES", "Double quotes used where single quotes suffice: " unnecessary_dq_hits)
      if (sc2015_hits != "") emit(f, "SC2015_AND_OR", "SC2015-prone A && B || true chain (use explicit if ...; then ... || true; fi): " sc2015_hits)
      if (bad_stack_quote_hits != "") emit(f, "RECURSION_GUARD", "Single-quoted literal ${THIS_FILE} in STACK guard (SC2016 bug): " bad_stack_quote_hits)
      if (unreachable_stack_hits != "") emit(f, "RECURSION_GUARD", "Unreachable STACK pop after return/exit (SC2317 bug): " unreachable_stack_hits)

      if (f ~ /^_lib\/kernel\/(zephyr|freertos)\/.*\.sh$/) {
        if (boundary_hits != "") emit(f, "RECIPE_BOUNDARY", "RTOS kernel recipe directly invokes host mount/partition primitive: " boundary_hits)
        if (venv_leak_hits != "") emit(f, "RTOS_VENV_LEAK", "RTOS kernel recipe creates Python venv outside LIBSCRIPT_HOME: " venv_leak_hits)
      } else if (f ~ /^_lib\/[^\/]+\/[^\/]+\/.*\.sh$/ && f !~ /^_lib\/(orchestration|kernel|bootloaders|freebsd|illumos|reactos)\// && f !~ /\/_common\//) {
        if (boundary_hits != "") emit(f, "RECIPE_BOUNDARY", "Tier 1 leaf recipe directly invokes kernel/storage primitive: " boundary_hits)
      }
      if (f ~ /^_lib\/.*\/env\.sh$/ && unguarded_sh_path != "") {
        emit(f, "ENV_PATH_IDEMPOTENCY", "Unguarded export PATH=\"...:$PATH\" in env.sh duplicates PATH entries on re-run: " unguarded_sh_path)
      }
      if ((f ~ /^(_lib|cli|devtools|tests)\/.*\.sh$/) && f !~ /^_lib\/.*\/test[^\/]*\.sh$/ && f !~ /(test_standards_|audit_standards\.sh$)/ && interp_hits != "") {
        emit(f, "ZERO_DEP_SUBSTRATE", "Core or recipe script invokes external interpreter inline: " interp_hits)
      }
      if ((f ~ /^_lib\// || f ~ /^cli\//) && leak_hits != "") {
        emit(f, "NO_HARDCODED_USER_PATHS", "Hardcoded user/project path or .volta reference in substrate: " leak_hits)
      }
      if (f ~ /^_lib\/[^\/]+\/[^\/]+\/setup[^\/]*\.sh$/ && commented_dep_hits != "") {
        emit(f, "COMMENTED_DEPENDS", "Commented-out \x27# # libscript_depends\x27 found in recipe setup script: " commented_dep_hits)
      }
      if ((f == "engine/common/pkg_mgr.sh" || f == "engine/common/os_info.sh") && !has_stack_pop) {
        emit(f, "STACK_HYGIENE", "Common library script must pop THIS_FILE from STACK on completion.")
      }
      if (f ~ /^_lib\/[^\/]+\/[^\/]+\/env\.sh$/ && has_bare_home) {
        emit(f, "SET_FEU_SAFETY", "Unguarded $HOME reference in env.sh; use ${HOME:-/root} for set -u daemon safety.")
      }
      if (f !~ /audit_standards\.sh$/ && libscript_home_bare_hits != "") {
        emit(f, "SET_FEU_SAFETY", "Unguarded ${LIBSCRIPT_HOME:-$HOME/...} under set -feu; use ${HOME:-/root}: " libscript_home_bare_hits)
      }
      if (f !~ /audit_standards\.sh$/ && self_exec_dollar0_hits != "") {
        emit(f, "THIS_FILE_DANCE", "Self-re-invocation via $0 instead of STACK=\x27\x27 ... \"${THIS_FILE}\": " self_exec_dollar0_hits)
      }
      if (f !~ /audit_standards\.sh$/ && unzip_no_o_hits != "") {
        emit(f, "IDEMPOTENCY", "Non-idempotent unzip without -o overwrite flag: " unzip_no_o_hits)
      }
    }
    BEGIN { prev_file = ""; reset_sh() }
    FNR == 1 {
      if (prev_file != "") flush_sh(prev_file)
      prev_file = FILENAME
      reset_sh()
    }
    {
      if ($0 ~ /\r$/) {
        has_crlf = 1
        sub(/\r$/, "", $0)
      }
      if (FNR == 1) first_line = $0
      if (FNR <= 30) {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
        if ($0 !~ /^[[:space:]]*#/) {
          if ($0 ~ /set -feu/) has_set_feu = 1
          if ($0 ~ /THIS_FILE=/) has_this_file = 1
          if ($0 ~ /STACK/) has_stack = 1
          if ($0 ~ /LIBSCRIPT_ROOT_DIR/) has_root_dir = 1
        }
        if ($0 ~ /# shellcheck disable=SC2296/) has_zsh_sc = 1
      }
      if ($0 ~ /STACK=.*THIS_FILE/) has_stack_pop = 1
      if ($0 !~ /^[[:space:]]*#/ && ($0 ~ /\$HOME([^A-Za-z0-9_]|$)/ || $0 ~ /\$\{HOME\}/)) has_bare_home = 1
      if ($0 ~ /^[[:space:]]*(sudo[[:space:]]+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)[[:space:]]/) {
        boundary_hits = (boundary_hits ? boundary_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /python3?[[:space:]]+-m[[:space:]]+venv[[:space:]]+(\/tmp|~\/|[$]HOME\/|\.\/\.venv)/) {
        venv_leak_hits = (venv_leak_hits ? venv_leak_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /^[[:space:]]*export[[:space:]]+PATH="[^"]+:\$\{?PATH(:-)?\}?"/) {
        unguarded_sh_path = (unguarded_sh_path ? unguarded_sh_path "; " : "") FNR ":" $0
      }
      if ($0 ~ /(^[[:space:]]*|\$\()(python3?[[:space:]]+(-c|-[[:space:]]*<<|<<)|node[[:space:]]+(-e|-[[:space:]]*<<|<<)|perl[[:space:]]+(-e|-[[:space:]]*<<|<<)|ruby[[:space:]]+(-e|-[[:space:]]*<<|<<))|libscript-allow-interp/) {
        interp_hits = (interp_hits ? interp_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /(pulse_query|pulse-query|hospital-dashboard-platform|hospital_dashboard_platform|t1d_analytics|t1d-analytics|T1D_|\/mnt\/data\/t1d|\/Volumes\/TOSHIBA_EXT|e4s2024|E4S2024|\/opt\/conda\/envs|\/home\/azureuser|C:\\Users\\vagrant|\.volta\/bin)/) {
        leak_hits = (leak_hits ? leak_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /^[[:space:]]*#[[:space:]]*#[[:space:]]*libscript_depends/) {
        commented_dep_hits = (commented_dep_hits ? commented_dep_hits "; " : "") FNR ":" $0
      }

      if (in_heredoc) {
        cur = $0
        sub(/^[[:space:]]+/, "", cur)
        sub(/[[:space:]]+$/, "", cur)
        if (cur == delim || cur ~ ("^" delim "[\x27\"][[:space:]<>|/A-Za-z0-9_.-]*$")) {
          in_heredoc = 0
          heredoc_quoted = 0
          delim = ""
          next
        }
        if (!heredoc_quoted && $0 ~ /\$\{LIBSCRIPT_HOME:-\$(\{HOME\}|HOME)\//) {
          libscript_home_bare_hits = (libscript_home_bare_hits ? libscript_home_bare_hits "; " : "") FNR ":" $0
        }
        next
      }
      idx = index($0, "<<")
      if (idx > 0) {
        rest = substr($0, idx + 2)
        sub(/^[ -]+/, "", rest)
        hd_q = (rest ~ /^(\\|["\x27])/) ? 1 : 0
        sub(/^\\+/, "", rest)
        sub(/["\x27]/, "", rest)
        sub(/["\x27].*$/, "", rest)
        sub(/[[:space:]].*$/, "", rest)
        if (rest != "") {
          in_heredoc = 1
          heredoc_quoted = hd_q
          delim = rest
        }
      }
      if ($0 ~ /^#!/) {
        shebang_count++
        shebang_lines = (shebang_lines ? shebang_lines ", " : "") FNR
      }
      if ($0 !~ /^[[:space:]]*#/ && ($0 ~ /(^|[[:space:];|&(])mkdir[[:space:]]+[^-\r\n]/ || ($0 ~ /(^|[[:space:];|&(])(priv[[:space:]]+)?mkdir[[:space:]]+-m[[:space:]]+/ && $0 !~ /[[:space:]]-[a-zA-Z]*p/)) && tolower($0) !~ /lock|while|if[[:space:]]+!|if[[:space:]]+not[[:space:]]+exist|vagrant[[:space:]]+ssh/) {
        mkdir_hits = (mkdir_hits ? mkdir_hits "; " : "") FNR ":" $0
      }
      if ($0 !~ /^[[:space:]]*#/ && $0 ~ /(^|[[:space:];|&(])ln[[:space:]]+-s[[:space:]]+[^-\r\n]/) {
        ln_hits = (ln_hits ? ln_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /^[[:space:]]*eval([[:space:]]|$)/ || ($0 !~ /^[[:space:]]*#/ && $0 ~ /(;|\|\||&&|\||\$\()[[:space:]]*eval([[:space:]]|$)/)) {
        eval_hits = (eval_hits ? eval_hits "; " : "") FNR ":" $0
      }
      if ($0 !~ /^[[:space:]]*#/ && $0 ~ /if[[:space:]]+![[:space:]]*\([[:space:]]*return[[:space:]]+0([^0-9]|$)/) {
        dash_return_probe_hits = (dash_return_probe_hits ? dash_return_probe_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
        git_push_hits = (git_push_hits ? git_push_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /^[[:space:]]*#/) {
        allow_pkg_next = ($0 ~ /libscript-allow-raw-pkg/) ? 1 : 0
        allow_fetch_next = ($0 ~ /libscript-allow-raw-(fetch|curl)/) ? 1 : 0
        allow_daemon_next = ($0 ~ /libscript-allow-raw-daemon/) ? 1 : 0
        allow_sync_next = ($0 ~ /libscript-allow-raw-sync/) ? 1 : 0
        allow_venv_next = ($0 ~ /libscript-allow-raw-venv/) ? 1 : 0
        allow_priv_next = ($0 ~ /libscript-allow-raw-priv/) ? 1 : 0
        allow_envsubst_next = ($0 ~ /libscript-allow-raw-envsubst/) ? 1 : 0
        allow_uuid_next = ($0 ~ /libscript-allow-raw-uuid/) ? 1 : 0
        allow_hw_next = ($0 ~ /libscript-allow-raw-hw/) ? 1 : 0
        allow_extvm_next = ($0 ~ /libscript-allow-ext-vm/) ? 1 : 0
        allow_uname_next = ($0 ~ /libscript-allow-raw-uname/) ? 1 : 0
        if ($0 ~ /^#[[:space:]]*Performs the .* operation and updates component state\.$/) {
          placeholder_doc_hits = (placeholder_doc_hits ? placeholder_doc_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_daemon_next && $0 !~ /libscript-allow-raw-daemon/) {
        if ($0 ~ /(^|[[:space:];|&(])(priv[[:space:]]+|sudo[[:space:]]+)?(systemctl[[:space:]]+(start|stop|restart|reload|reload-or-restart|daemon-reload|enable|disable|status|is-active)|launchctl[[:space:]]+(load|unload|start|stop|kickstart|bootstrap|bootout)|rc-service[[:space:]]+|rc-update[[:space:]]+(add|del)|svcadm[[:space:]]+(enable|disable|restart|refresh)|svccfg[[:space:]]+(import|delete)|sc\.exe[[:space:]]+(start|stop|create|delete|config|query|description)|sc[[:space:]]+(start|stop|create|delete|config|query|description)|net[[:space:]]+(start|stop)[[:space:]]+|service[[:space:]]+[A-Za-z0-9_$"\x27-]+[[:space:]]+(start|stop|restart|reload|status|onestatus)|update-rc\.d[[:space:]]+|chkconfig[[:space:]]+|s6-svc[[:space:]]+|dinitctl[[:space:]]+|sysrc[[:space:]]+[A-Za-z0-9_$"\x27-]*_enable|journalctl[[:space:]]+-u[[:space:]]+)([[:space:];|&)]|$)/) {
          raw_daemon_hits = (raw_daemon_hits ? raw_daemon_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_pkg_next && $0 !~ /libscript-allow-raw-pkg/) {
        if ($0 ~ /(^|[[:space:];|&])(priv[[:space:]]+|sudo[[:space:]]+)?(apt-get[[:space:]]+(install|remove|purge|update)|apt[[:space:]]+(install|remove|purge)|apk[[:space:]]+(add|del|update)|dnf[[:space:]]+(install|remove|groupinstall)|yum[[:space:]]+(install|remove|groupinstall)|pacman[[:space:]]+(-S|-R|-Rns|-Syu)|zypper[[:space:]]+(install|in|remove|rm)|brew[[:space:]]+(install|uninstall|tap|services)|port[[:space:]]+(install|uninstall)|pkg[[:space:]]+(install|delete|add)|xbps-install|xbps-remove|emerge[[:space:]]|swupd[[:space:]]+bundle-add|winget[[:space:]]+(install|uninstall|upgrade)|choco[[:space:]]+(install|uninstall|upgrade)|scoop[[:space:]]+(install|uninstall|update)|vcpkg[[:space:]]+(install|remove)|conan[[:space:]]+install|nix[[:space:]]+profile[[:space:]]+install|nix-env[[:space:]]+-i|guix[[:space:]]+(install|package)|spack[[:space:]]+(install|uninstall)|npm[[:space:]]+install[[:space:]]+-g|composer[[:space:]]+global[[:space:]]+require)([[:space:]]|$)/) {
          if ($0 !~ /--root/) {
            adhoc_pkg_hits = (adhoc_pkg_hits ? adhoc_pkg_hits "; " : "") FNR ":" $0
          }
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_fetch_next && $0 !~ /libscript-allow-raw-(fetch|curl)/) {
        if ($0 ~ /(^|[[:space:];|&(])(curl(\.exe)?[[:space:]]+(--(silent|location|fail|output)|-[a-zA-Z0-9#-]*[sSfLOo])|wget(\.exe)?[[:space:]]+(--(quiet|output-document)|-[a-zA-Z0-9-]*[qO])|aria2c[[:space:]]+-[dox])([[:space:]]|$)/ && $0 !~ /(127\.0\.0\.1|localhost|--unix-socket|--cacert|--connect-timeout|-w[[:space:]]+"%\{http_code\}")/) {
          raw_fetch_hits = (raw_fetch_hits ? raw_fetch_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_sync_next && $0 !~ /libscript-allow-raw-sync/) {
        if ($0 ~ /(^|[[:space:];|&(])(rsync[[:space:]]+-[a-zA-Z0-9-]*.*:|scp[[:space:]]+(-[a-zA-Z0-9]+[[:space:]]+)*[^[:space:]|;&]+)[[:space:]]+/ && $0 !~ /(gcloud[[:space:]]+(compute|storage)|vagrant[[:space:]]+rsync|cli\.(sh|cmd)[[:space:]"]*scp|log_(info|warn|error)|--version|command[[:space:]]+-v)/) {
          raw_sync_hits = (raw_sync_hits ? raw_sync_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_venv_next && $0 !~ /libscript-allow-raw-venv/) {
        if ($0 ~ /(^|[[:space:];|&(])(priv([_a-z]*)[[:space:]]+([A-Za-z0-9_$"'\''-]+[[:space:]]+)?)?([A-Za-z0-9_$"'\''\/.-]*python[0-9.]*[[:space:]]+-m[[:space:]]+venv|uv[[:space:]]+venv|virtualenv[[:space:]]+)/) {
          raw_venv_hits = (raw_venv_hits ? raw_venv_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_priv_next && $0 !~ /libscript-allow-raw-priv/) {
        if ($0 ~ /(^|[[:space:];|&(])sudo[[:space:]]+(-u[[:space:]]+[A-Za-z0-9_$-]+[[:space:]]+|[A-Za-z0-9_\/.-]+)/ && $0 !~ /(command[[:space:]]+-v[[:space:]]+sudo|sudo[[:space:]]+(-V|--version|-n[[:space:]]+true)|node[[:space:]]+exec|vagrant[[:space:]]+ssh|echo[[:space:]]|printf[[:space:]])/) {
          raw_priv_hits = (raw_priv_hits ? raw_priv_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_envsubst_next && $0 !~ /libscript-allow-raw-envsubst/) {
        if ($0 ~ /(^|[[:space:];|&(])(\$\(command[[:space:]]+-v[[:space:]]+envsubst\)|envsubst)([[:space:]<>]|$)/ && $0 !~ /(envsubst_safe|command[[:space:]]+-v[[:space:]]+envsubst[[:space:]]+>)/) {
          raw_envsubst_hits = (raw_envsubst_hits ? raw_envsubst_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_uuid_next && $0 !~ /libscript-allow-raw-uuid/) {
        if ($0 ~ /(^|[[:space:];|&(])(uuidgen([[:space:]]|$)|cat[[:space:]]+\/proc\/sys\/kernel\/random\/uuid)/) {
          raw_uuid_hits = (raw_uuid_hits ? raw_uuid_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_hw_next && $0 !~ /libscript-allow-raw-hw/) {
        if ($0 ~ /\$\(nproc([[:space:]]|\))|\$\(sysctl[[:space:]]+-n[[:space:]]+hw\.(ncpu|memsize|physmem)/) {
          raw_hw_hits = (raw_hw_hits ? raw_hw_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_extvm_next && $0 !~ /libscript-allow-ext-vm/) {
        if ($0 ~ /(^|[[:space:];|&(])(rustup[[:space:]]+toolchain[[:space:]]+install|nvm[[:space:]]+install|fnm[[:space:]]+install|pyenv[[:space:]]+install|rbenv[[:space:]]+install|sdk[[:space:]]+install|volta[[:space:]]+install)([[:space:]]|$)/) {
          ext_vm_hits = (ext_vm_hits ? ext_vm_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_uname_next && $0 !~ /libscript-allow-raw-uname/) {
        if ($0 ~ /(\$\(uname([[:space:]\)]|$)|(^|[[:space:];|&(])uname([[:space:]]+-[a-zA-Z]+)?([[:space:];|&)]|$))/ && $0 !~ /(vagrant[[:space:]]+ssh|echo[[:space:]]|printf[[:space:]])/) {
          raw_uname_hits = (raw_uname_hits ? raw_uname_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && $0 !~ /libscript-allow-raw-tpu/) {
        if ($0 ~ /gcloud[[:space:]]+compute[[:space:]]+tpus[[:space:]]+tpu-vm/ && $0 !~ /(echo[[:space:]]|printf[[:space:]])/) {
          raw_tpu_hits = (raw_tpu_hits ? raw_tpu_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/) {
        allow_pkg_next = 0; allow_fetch_next = 0; allow_daemon_next = 0;
        allow_sync_next = 0; allow_venv_next = 0; allow_priv_next = 0;
        allow_envsubst_next = 0; allow_uuid_next = 0; allow_hw_next = 0;
        allow_extvm_next = 0; allow_uname_next = 0;
        if ($0 ~ /\*\x27:"\$\{THIS_FILE\}":\x27\*/) {
          bad_stack_quote_hits = (bad_stack_quote_hits ? bad_stack_quote_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /ACTION=[\x27"]?install[\x27"]?[[:space:]]+"\$0"/) {
          self_exec_dollar0_hits = (self_exec_dollar0_hits ? self_exec_dollar0_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /\$\{LIBSCRIPT_HOME:-\$(\{HOME\}|HOME)\//) {
          libscript_home_bare_hits = (libscript_home_bare_hits ? libscript_home_bare_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /(^|[[:space:];|&(])unzip[[:space:]]+-q[[:space:]]+/ && $0 !~ /[[:space:]]-[a-zA-Z]*o([[:space:]]|$)/) {
          unzip_no_o_hits = (unzip_no_o_hits ? unzip_no_o_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /^if \(return 0 2>\/dev\/null\); then return 0; else exit 0; fi$/) {
          saw_top_ret_nr = FNR
        }
        if (saw_top_ret_nr > 0 && FNR == saw_top_ret_nr + 1 && $0 ~ /^STACK=/) {
          unreachable_stack_hits = (unreachable_stack_hits ? unreachable_stack_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /SCRIPT_NAME=/) {
          last_script_name_nr = FNR
        }
        if ($0 ~ /(^|[[:space:];|&()])\.[[:space:]]+["\x27]?(\$[{]?SCRIPT_DIR[}]?|\$[{]?LIBSCRIPT_ROOT_DIR[}]?|\$[{]?REPO_ROOT[}]?)\/[^[:space:]"\x27;]+\.sh["\x27]?([[:space:];|&)]|$)/) {
          if (FNR - last_script_name_nr > 4 && $0 !~ /SCRIPT_NAME/) {
            unguarded_src_hits = (unguarded_src_hits ? unguarded_src_hits "; " : "") FNR ":" $0
          }
        }
        if ($0 ~ /^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*="[A-Za-z0-9_.\/:@+-]+"[[:space:]]*$/ ||
            $0 ~ /^[[:space:]]*(log_(info|warn|error)|printf[[:space:]]+\x27%s\\n\x27|echo)[[:space:]]+"[^$`\x5c\x27"]+"([[:space:]]*>&2)?[[:space:]]*$/ ||
            $0 ~ /^[[:space:]]*libscript_depends([[:space:]]+"[A-Za-z0-9_.-]+")+([[:space:]]*\|\|[[:space:]]*true)?[[:space:]]*$/) {
          unnecessary_dq_hits = (unnecessary_dq_hits ? unnecessary_dq_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /^[ \t]*(\x5b[^\x5d]+\x5d([ \t]*&&[ \t]*\x5b[^\x5d]+\x5d)*|command[ \t]+-v[ \t]+[^|;]+)[ \t]*&&[ \t]*[^|;&\x5b{][^|;&]*(\|[ \t]*[^|;&]+)*\|\|[ \t]*(true|:)([ \t;]|$)/ ||
            $0 ~ /\$\([ \t]*cd[ \t]+[^|;&]+&&[ \t]*[^|;&]+(\|[ \t]*[^|;&]+)*\|\|[ \t]*(true|:)[ \t]*\)/) {
          sc2015_hits = (sc2015_hits ? sc2015_hits "; " : "") FNR ":" $0
        }
      }
    }
    END {
      if (prev_file != "") flush_sh(prev_file)
    }
  ' "$@" 2>/dev/null || true)

  if [ -n "$_sh_out" ]; then
    OIFS_S="$IFS"
    IFS='
'
    for _sl in $_sh_out; do
      _sf="${_sl%%|*}"
      _sh_rest="${_sl#*|}"
      _sr="${_sh_rest%%|*}"
      _sm="${_sh_rest#*|}"
      report_sh_violation "$_sf" "$_sr" "$_sm"
    done
    IFS="$OIFS_S"
  fi
}

# shellcheck disable=SC2329
# ## audit_ps1_batch
# Evaluates a batch of PowerShell .ps1 files in a single multi-file awk pass plus companion parity checks.
audit_ps1_batch() {
  [ "$#" -gt 0 ] || return 0
  for _apb_f in "$@"; do
    _apb_sh="${_apb_f%.ps1}.sh"
    _apb_cmd="${_apb_f%.ps1}.cmd"
    if [ ! -f "$_apb_sh" ]; then
      log_failure "$_apb_f" 'POSIX_PARITY' "Missing POSIX shell equivalent file ('$_apb_sh') for PowerShell script."
    fi
    if [ ! -f "$_apb_cmd" ]; then
      log_failure "$_apb_f" 'WINDOWS_PARITY' "Missing Windows batch equivalent file ('$_apb_cmd') for PowerShell script."
    fi
  done

  _ps1_out=$(awk '
    BEGIN {} function reset_ps1() {
      has_overview = 0; has_usage = 0; eval_hits = ""; git_push_hits = "";
      raw_fetch_hits = ""; raw_pkg_hits = ""; raw_daemon_hits = "";
      bs_quote_hits = ""; static_arg_hits = ""; paren_kw_hits = ""; bare_cmd_hits = "";
      allow_fetch_next = 0; allow_pkg_next = 0; allow_daemon_next = 0;
      has_exit_86 = 0; leak_hits = "";
    }
    BEGIN {} function emit(f, r, m) { print f "|" r "|" m }
    BEGIN {} function flush_ps1(f) {
      if (f == "") return
      if (!has_overview) emit(f, "DOC_OVERVIEW", "Missing doc block ## Overview in first 30 lines.")
      if (!has_usage) emit(f, "DOC_USAGE", "Missing doc block ## Usage in first 30 lines.")
      if (eval_hits != "") emit(f, "BAN_EVAL", "Disallowed use of Invoke-Expression found: " eval_hits)
      if (git_push_hits != "") emit(f, "REMOTE_SAFETY", "Strict safety violation: found git push invocation: " git_push_hits)
      if (raw_fetch_hits != "") emit(f, "RAW_NETWORK_FETCH", "Raw Invoke-WebRequest/Invoke-RestMethod found (delegate to pkg_mgr.ps1): " raw_fetch_hits)
      if (raw_pkg_hits != "") emit(f, "RAW_PACKAGE_MANAGER", "Raw winget/choco/scoop invocation found (delegate to pkg_mgr.ps1): " raw_pkg_hits)
      if (raw_daemon_hits != "") emit(f, "RAW_DAEMON_MANAGER", "Raw Windows service cmdlet or sc.exe invocation found (delegate to service.ps1 or service_install.ps1): " raw_daemon_hits)
      if (bs_quote_hits != "") emit(f, "PS1_SYNTAX", "C-style backslash quote escape found in PowerShell script (use backtick or double quotes): " bs_quote_hits)
      if (static_arg_hits != "") emit(f, "PS1_SYNTAX", "Unparenthesized static method call passed as command argument: " static_arg_hits)
      if (paren_kw_hits != "") emit(f, "PS1_SYNTAX", "Statement keyword inside (...) instead of $(...) subexpression: " paren_kw_hits)
      if (bare_cmd_hits != "") emit(f, "PS1_SYNTAX", "Unparenthesized cmdlet call followed by operator in condition (wrap cmdlet call in parentheses): " bare_cmd_hits)
      if (f ~ /\/(mount_target_vfs|umount_target_vfs|runner|provision_disk|format_fs|live_freebsd|live_illumos|live_reactos|live_linux|coinstall_dual_os|install_freebsd|install_illumos|install_reactos|install_linux|multiboot_orchestrator|grub_multiboot|alpine-systemctl|setup_debian|setup_alpine|setup_freebsd|setup_macos|setup_rhel|setup_illumos|setup_linux)\.ps1$/ && !has_exit_86) {
        emit(f, "OPTION_A_PROFORMA", "Option A proforma script must exit with status 86.")
      }
      if ((f ~ /^_lib\// || f ~ /^cli\//) && leak_hits != "") {
        emit(f, "NO_HARDCODED_USER_PATHS", "Hardcoded user/project path or .volta reference in substrate: " leak_hits)
      }
    }
    BEGIN { prev_file = ""; reset_ps1() }
    FNR == 1 {
      if (prev_file != "") flush_ps1(prev_file)
      prev_file = FILENAME
      reset_ps1()
    }
    {
      sub(/\r$/, "", $0)
      if (FNR <= 30) {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      if ($0 ~ /exit 86/) has_exit_86 = 1
      if ($0 ~ /(pulse_query|pulse-query|hospital-dashboard-platform|hospital_dashboard_platform|t1d_analytics|t1d-analytics|T1D_|\/mnt\/data\/t1d|\/Volumes\/TOSHIBA_EXT|e4s2024|E4S2024|\/opt\/conda\/envs|\/home\/azureuser|C:\\Users\\vagrant|\.volta\/bin)/) {
        leak_hits = (leak_hits ? leak_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /^[[:space:]]*#/) {
        allow_fetch_next = ($0 ~ /libscript-allow-raw-(fetch|curl)/) ? 1 : 0
        allow_pkg_next = ($0 ~ /libscript-allow-raw-pkg/) ? 1 : 0
        allow_daemon_next = ($0 ~ /libscript-allow-raw-daemon/) ? 1 : 0
        next
      }
      if (tolower($0) ~ /^[[:space:]]*(invoke-expression|iex)([[:space:]]|$)/) {
        eval_hits = (eval_hits ? eval_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
        git_push_hits = (git_push_hits ? git_push_hits "; " : "") FNR ":" $0
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_fetch_next && $0 !~ /libscript-allow-raw-(fetch|curl)/) {
        if (tolower($0) ~ /(^|[[:space:];|&(])(invoke-webrequest|invoke-restmethod|iwr|irm|start-bitstransfer|net\.webclient)([[:space:]]|$)/ && tolower($0) !~ /(127\.0\.0\.1|localhost)/) {
          raw_fetch_hits = (raw_fetch_hits ? raw_fetch_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_pkg_next && $0 !~ /libscript-allow-raw-pkg/) {
        if (tolower($0) ~ /(^|[[:space:];|&&])(winget[[:space:]]+(install|uninstall|upgrade)|choco[[:space:]]+(install|uninstall|upgrade)|scoop[[:space:]]+(install|uninstall|update))([[:space:]]|$)/) {
          raw_pkg_hits = (raw_pkg_hits ? raw_pkg_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/ && !allow_daemon_next && $0 !~ /libscript-allow-raw-daemon/) {
        if (tolower($0) ~ /(^|[[:space:];|&(])(start-service|stop-service|restart-service|set-service|new-service|sc\.exe[[:space:]]+(start|stop|create|delete|config|query|description)|net[[:space:]]+(start|stop))([[:space:]]|$)/) {
          raw_daemon_hits = (raw_daemon_hits ? raw_daemon_hits "; " : "") FNR ":" $0
        }
      }
      if ($0 !~ /^[[:space:]]*#/) {
        if ($0 ~ /\\"/ && FILENAME !~ /(audit_standards|doc_coverage|update_results|generate_html_docs)\.ps1$/) {
          bs_quote_hits = (bs_quote_hits ? bs_quote_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /(Join-Path|Test-Path|Copy-Item|Move-Item|Remove-Item|New-Item|Set-Content|Add-Content|Get-Content)[[:space:]]+[^(\r\n]*\[[A-Za-z0-9_.]+\]::[A-Za-z0-9_]+\(/) {
          static_arg_hits = (static_arg_hits ? static_arg_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /[A-Za-z0-9_-]+[[:space:]]+[^#;\r\n]*[^$]\([[:space:]]*(if|switch|foreach|for|while|try)[[:space:]]*\(/) {
          paren_kw_hits = (paren_kw_hits ? paren_kw_hits "; " : "") FNR ":" $0
        }
        if ($0 ~ /(^|[[:space:]}])(if|elseif|while)[[:space:]]*\([[:space:]]*[A-Za-z]+-[A-Za-z]+[^()\r\n]*[[:space:]]-(and|or|xor|eq|ne|gt|ge|lt|le|match|notmatch|like|notlike)([[:space:]]|$)/) {
          bare_cmd_hits = (bare_cmd_hits ? bare_cmd_hits "; " : "") FNR ":" $0
        }
      }
      allow_fetch_next = 0; allow_pkg_next = 0; allow_daemon_next = 0;
    }
    END {
      if (prev_file != "") flush_ps1(prev_file)
    }
  ' "$@" 2>/dev/null || true)

  if [ -n "$_ps1_out" ]; then
    OIFS_P="$IFS"
    IFS='
'
    for _pl in $_ps1_out; do
      _pf="${_pl%%|*}"
      _prest="${_pl#*|}"
      _pr="${_prest%%|*}"
      _pm="${_prest#*|}"
      report_ps1_violation "$_pf" "$_pr" "$_pm"
    done
    IFS="$OIFS_P"
  fi
}

# shellcheck disable=SC2329
# ## audit_cmd_batch
# Evaluates a batch of Windows Batch .cmd/.bat files in a single multi-file awk pass plus companion parity checks.
audit_cmd_batch() {
  [ "$#" -gt 0 ] || return 0
  for _acb_f in "$@"; do
    _acb_sh="${_acb_f%.*}.sh"
    if [ ! -f "$_acb_sh" ]; then
      log_failure "$_acb_f" 'POSIX_PARITY' "Missing POSIX shell equivalent file ('$_acb_sh') for Windows batch script."
    fi
  done

  _cmd_out=$(awk '
    BEGIN {} function reset_cmd() {
      has_echo_off = 0; has_delayed = 0; has_this_file = 0; has_stack_guard = 0;
      has_overview = 0; has_usage = 0; has_dup_stack = 0;
      mkdir_hits = ""; git_push_hits = ""; script_dir_hits = ""; chained_if_else_hits = "";
      dp0_double_bs_hits = ""; bad_script_dir_strip = ""; tab_path_hits = "";
      endlocal_delayed_hits = ""; for_r_delayed_hits = ""; placeholder_doc_hits = "";
      raw_fetch_hits = ""; raw_pkg_hits = ""; raw_daemon_hits = "";
      raw_sync_hits = ""; raw_venv_hits = ""; raw_uuid_hits = "";
      allow_fetch_next = 0; allow_pkg_next = 0; allow_daemon_next = 0;
      allow_sync_next = 0; allow_venv_next = 0; allow_uuid_next = 0;
      in_endlocal = 0; in_ls_remote = 0; spliced_guard_hits = ""; lone_cr_hits = "";
      del_exp_active = 0; quoted_dbl_caret_bang_hits = ""; bare_exit_hits = "";
      dup_label_hits = ""; has_exit_86 = 0; has_setlocal_any = 0; has_endlocal_any = 0;
      unguarded_cmd_path = ""; leak_hits = ""; has_caller_script_dir = 0;
      call_dp0_self_hits = ""; stale_mklink_hits = ""; has_cmd_root = 0; cmd_root_clobber_hits = "";
      empty_paren_hits = ""; prev_open_paren = 0; prev_open_ln = 0;
      split("", defined_labels); split("", goto_targets); split("", call_targets); split("", chained_if);
    }
    BEGIN {} function emit(f, r, m) { print f "|" r "|" m }
    BEGIN {} function flush_cmd(f,   missing_lbl_hits, ln_no, t, bn) {
      if (f == "") return
      defined_labels["eof"] = 1
      missing_lbl_hits = ""
      for (ln_no in goto_targets) {
        t = goto_targets[ln_no]
        if (!(t in defined_labels)) {
          missing_lbl_hits = (missing_lbl_hits ? missing_lbl_hits "; " : "") "line " ln_no " (goto :" t ")"
        }
      }
      for (ln_no in call_targets) {
        t = call_targets[ln_no]
        if (!(t in defined_labels)) {
          missing_lbl_hits = (missing_lbl_hits ? missing_lbl_hits "; " : "") "line " ln_no " (call :" t ")"
        }
      }
      if (!has_echo_off) emit(f, "BATCH_ECHO_OFF", "Missing @echo off on line 1.")
      if (!has_delayed) emit(f, "BATCH_DELAYED_EXPANSION", "Missing setlocal EnableDelayedExpansion in first 25 lines (before :find_root).")
      if (!has_this_file) emit(f, "BATCH_THIS_FILE", "Missing set \"THIS_FILE=%~f0\" in first 25 lines.")
      if (!has_stack_guard) emit(f, "BATCH_STACK_GUARD", "Missing quoted case-insensitive STACK guard (echo \"!STACK!\" | findstr /I /C:\":!THIS_FILE!:\") in first 25 lines.")
      if (has_dup_stack) emit(f, "BATCH_DUPLICATE_STACK", "Duplicate legacy searchVal=;%THIS_FILE%; STACK block found.")
      if (!has_cmd_root) emit(f, "CMD_ROOT_DIR_RESOLUTION", "Missing :find_root / LIBSCRIPT_ROOT_DIR resolution in batch script.")
      if (cmd_root_clobber_hits != "") emit(f, "CMD_ROOT_CLOBBER", "Batch script overwrites LIBSCRIPT_ROOT_DIR via SCRIPT_DIR\\..: " cmd_root_clobber_hits)
      if (!has_overview) emit(f, "DOC_OVERVIEW", "Missing doc block ## Overview in first 30 lines.")
      if (!has_usage) emit(f, "DOC_USAGE", "Missing doc block ## Usage in first 30 lines.")
      if (placeholder_doc_hits != "") emit(f, "DOC_PLACEHOLDER", "Auto-generated placeholder docstring found: " placeholder_doc_hits)
      if (mkdir_hits != "") emit(f, "IDEMPOTENCY", "Unguarded mkdir in batch script: " mkdir_hits)
      if (git_push_hits != "") emit(f, "REMOTE_SAFETY", "Strict safety violation: found git push invocation: " git_push_hits)
      if (script_dir_hits != "") emit(f, "BATCH_SCRIPT_DIR_SEPARATOR", "Missing backslash after SCRIPT_DIR: " script_dir_hits)
      if (dp0_double_bs_hits != "") emit(f, "BATCH_DP0_DOUBLE_BACKSLASH", "Double backslash %~dp0\\ found (use !LIBSCRIPT_ROOT_DIR! or !SCRIPT_DIR!\\): " dp0_double_bs_hits)
      if (bad_script_dir_strip != "") emit(f, "BATCH_SCRIPT_DIR_STRIP", "Corrupted SCRIPT_DIR:~-1 backslash check: " bad_script_dir_strip)
      if (tab_path_hits != "") emit(f, "BATCH_TAB_CORRUPTION", "Literal TAB character in path variable expansion: " tab_path_hits)
      if (endlocal_delayed_hits != "") emit(f, "BATCH_ENDLOCAL_DELAYED", "Delayed expansion !PATH! inside endlocal block: " endlocal_delayed_hits)
      if (for_r_delayed_hits != "") emit(f, "BATCH_FOR_R_DELAYED", "FOR /R root path uses !VAR! delayed expansion (parsed before !VAR! in cmd.exe; use pushd + FOR /R + popd): " for_r_delayed_hits)
      if (quoted_dbl_caret_bang_hits != "") emit(f, "BATCH_QUOTED_DOUBLE_CARET_BANG", "Double-caret ^^! inside double quotes under EnableDelayedExpansion (cmd.exe Pass 1 preserves ^^ inside quotes so Pass 2 unescapes !; use single ^! inside quotes): " quoted_dbl_caret_bang_hits)
      if (chained_if_else_hits != "") emit(f, "BATCH_CHAINED_IF_ELSE", "Chained if ... if ... ( ... ) else ( ... ) skips else when outer if is false: " chained_if_else_hits)
      if (raw_fetch_hits != "") emit(f, "RAW_NETWORK_FETCH", "Raw network call in batch script (delegate to pkg_mgr.cmd): " raw_fetch_hits)
      if (raw_pkg_hits != "") emit(f, "RAW_PACKAGE_MANAGER", "Raw winget/choco/scoop call in batch script (delegate to pkg_mgr.cmd): " raw_pkg_hits)
      if (raw_daemon_hits != "") emit(f, "RAW_DAEMON_MANAGER", "Raw service/daemon manager call in batch script (delegate to engine\\common\\service.cmd or service_install.cmd): " raw_daemon_hits)
      if (raw_sync_hits != "") emit(f, "RAW_REMOTE_SYNC", "Raw rsync/scp call in batch script (delegate to engine\\common\\remote_sync.cmd): " raw_sync_hits)
      if (raw_venv_hits != "") emit(f, "RAW_PYTHON_VENV", "Explicit Python venv creation in batch script (delegate to engine\\common\\python_env.cmd): " raw_venv_hits)
      if (raw_uuid_hits != "") emit(f, "RAW_UUID_GEN", "Non-deterministic Guid::NewGuid() in batch script (delegate to engine\\common\\uuid_gen.cmd): " raw_uuid_hits)
      if (bare_exit_hits != "") emit(f, "BATCH_HYGIENE", "Bare exit without /b found in batch script: " bare_exit_hits)
      if (call_dp0_self_hits != "") emit(f, "BATCH_THIS_FILE", "Self-re-invocation via call \"%~f0\" instead of STACK-cleared call \"!THIS_FILE!\": " call_dp0_self_hits)
      if (stale_mklink_hits != "") emit(f, "IDEMPOTENCY", "Non-idempotent if not exist ... mklink /J leaves stale/dangling junctions on re-run: " stale_mklink_hits)
      if (lone_cr_hits != "") emit(f, "BATCH_EOL_CRLF", "Double CR (\\r\\r\\n) or lone CR byte found in batch script: " lone_cr_hits)
      if (spliced_guard_hits != "") emit(f, "BATCH_SPLICED_GUARD", "Corrupted if exist guard spliced inside ls-remote block: " spliced_guard_hits)
      if (dup_label_hits != "") emit(f, "BATCH_DUPLICATE_LABEL", "Duplicate label definition(s) in batch script: " dup_label_hits)
      if (missing_lbl_hits != "") emit(f, "BATCH_MISSING_LABEL", "Undefined batch label target: " missing_lbl_hits)
      if (empty_paren_hits != "") emit(f, "EMPTY_BATCH_BLOCK", "Empty compound parenthesis block `( )` causes fatal cmd.exe syntax error: " empty_paren_hits)

      if (f ~ /(^|\/)(mount_target_vfs|umount_target_vfs|runner|provision_disk|format_fs|live_freebsd|live_illumos|live_reactos|live_linux|coinstall_dual_os|install_freebsd|install_illumos|install_reactos|install_linux|multiboot_orchestrator|grub_multiboot|alpine-systemctl|setup_debian|setup_alpine|setup_freebsd|setup_macos|setup_rhel|setup_illumos|setup_linux)\.cmd$/ && !has_exit_86) {
        emit(f, "OPTION_A_PROFORMA", "Option A proforma script must exit with status 86.")
      }
      if (f ~ /^_lib\/.*\/env\.cmd$/ || f == "engine/common/os_info.cmd") {
        if (has_setlocal_any && !has_endlocal_any) {
          bn = f; sub(/^.*\//, "", bn)
          emit(f, "ENV_CMD_ENDLOCAL", bn " uses setlocal without endlocal; PATH and variable updates will be lost on return.")
        }
        if (unguarded_cmd_path != "") {
          emit(f, "ENV_PATH_IDEMPOTENCY", "Unguarded set \"PATH=...;%PATH%\" in env.cmd duplicates PATH entries on re-run: " unguarded_cmd_path)
        }
      }
      if ((f ~ /^_lib\// || f ~ /^cli\//) && leak_hits != "") {
        emit(f, "NO_HARDCODED_USER_PATHS", "Hardcoded user/project path or .volta reference in substrate: " leak_hits)
      }
      if (f == "engine/common/env_base.cmd" && !has_caller_script_dir) {
        emit(f, "STACK_HYGIENE", "env_base.cmd must support CALLER_SCRIPT_DIR to prevent resolving PACKAGE_NAME to _common.")
      }
    }
    BEGIN { prev_file = ""; reset_cmd() }
    FNR == 1 {
      if (prev_file != "") flush_cmd(prev_file)
      prev_file = FILENAME
      reset_cmd()
    }
    {
      sub(/\r$/, "", $0)
      if (index($0, "\r") > 0) {
        sub(/\r+$/, "", $0)
        lone_cr_hits = (lone_cr_hits ? lone_cr_hits "; " : "") "line " FNR
      }
      if (FNR == 1 && tolower($0) == "@echo off") has_echo_off = 1
      if (FNR <= 25 && tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$))/) {
        if (tolower($0) ~ /^[[:space:]]*setlocal[[:space:]]+enabledelayedexpansion/) has_delayed = 1
        if (tolower($0) ~ /this_file=%~f0/) has_this_file = 1
        if (tolower($0) ~ /echo "!stack!" \| findstr \/i \/c:":/) has_stack_guard = 1
      }
      if (FNR <= 30) {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      if ($0 ~ /exit \/b 86/) has_exit_86 = 1
      if (tolower($0) ~ /setlocal/) has_setlocal_any = 1
      if (tolower($0) ~ /endlocal/) has_endlocal_any = 1
      if (tolower($0) ~ /^[[:space:]]*(endlocal[[:space:]]*&[[:space:]]*)?set[[:space:]]+"path=[^"]+;%path%"/) {
        unguarded_cmd_path = (unguarded_cmd_path ? unguarded_cmd_path "; " : "") FNR ":" $0
      }
      if ($0 ~ /(pulse_query|pulse-query|hospital-dashboard-platform|hospital_dashboard_platform|t1d_analytics|t1d-analytics|T1D_|\/mnt\/data\/t1d|\/Volumes\/TOSHIBA_EXT|e4s2024|E4S2024|\/opt\/conda\/envs|\/home\/azureuser|C:\\Users\\vagrant|\.volta\/bin)/) {
        leak_hits = (leak_hits ? leak_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /CALLER_SCRIPT_DIR/) has_caller_script_dir = 1
      if ($0 ~ /LIBSCRIPT_ROOT_DIR/) has_cmd_root = 1
      if (tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$))/ && tolower($0) ~ /set[[:space:]]+"?libscript_root_dir=[%!]script_dir[%!][\\\/]\.\./) {
        cmd_root_clobber_hits = (cmd_root_clobber_hits ? cmd_root_clobber_hits "; " : "") FNR ":" $0
      }

      if (tolower($0) ~ /searchval=;%this_file%;/) has_dup_stack = 1
      if (tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$)|echo([[:space:].]|$))/ && (tolower($0) ~ /^[[:space:]]*(mkdir|md)[[:space:]]+/ || tolower($0) ~ /([[:space:]]else|&|&&|\|\|)[[:space:]]+(mkdir|md)[[:space:]]+[^-\r\n]/) && tolower($0) !~ /if[[:space:]]+not[[:space:]]+exist|2>nul/) {
        mkdir_hits = (mkdir_hits ? mkdir_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
        git_push_hits = (git_push_hits ? git_push_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^if[[:space:]]+"%action%"=="ls-remote"[[:space:]]*\($/) {
        in_ls_remote = 1
      } else if (in_ls_remote && $0 ~ /^\)[[:space:]]*$/) {
        in_ls_remote = 0
      } else if (in_ls_remote && tolower($0) ~ /^if[[:space:]]+exist[[:space:]]+"%libscript_home%/) {
        spliced_guard_hits = (spliced_guard_hits ? spliced_guard_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^[[:space:]]*exit[[:space:]]+[0-9]+[[:space:]]*$/) {
        bare_exit_hits = (bare_exit_hits ? bare_exit_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$)|echo[[:space:]])/) {
        if (tolower($0) ~ /call[[:space:]]+"%~f0"/) {
          call_dp0_self_hits = (call_dp0_self_hits ? call_dp0_self_hits "; " : "") FNR ":" $0
        }
        if (tolower($0) ~ /if[[:space:]]+not[[:space:]]+exist[[:space:]].*mklink[[:space:]]+\/[dj]/) {
          stale_mklink_hits = (stale_mklink_hits ? stale_mklink_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) ~ /^[[:space:]]*(::|rem[[:space:]])/) {
        allow_fetch_next = ($0 ~ /libscript-allow-raw-(fetch|curl)/) ? 1 : 0
        allow_pkg_next = ($0 ~ /libscript-allow-raw-pkg/) ? 1 : 0
        allow_daemon_next = ($0 ~ /libscript-allow-raw-daemon/) ? 1 : 0
        allow_sync_next = ($0 ~ /libscript-allow-raw-sync/) ? 1 : 0
        allow_venv_next = ($0 ~ /libscript-allow-raw-venv/) ? 1 : 0
        allow_uuid_next = ($0 ~ /libscript-allow-raw-uuid/) ? 1 : 0
        if ($0 ~ /^::[[:space:]]*Performs the .* operation and updates component state\.$/) {
          placeholder_doc_hits = (placeholder_doc_hits ? placeholder_doc_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]]|echo[[:space:]])/ && !allow_fetch_next && $0 !~ /libscript-allow-raw-(fetch|curl)/) {
        if (tolower($0) ~ /(invoke-webrequest|invoke-restmethod|[[:space:]"]iwr[[:space:]]|[[:space:]"]irm[[:space:]]|certutil[[:space:]]+-urlcache|curl(\.exe)?[[:space:]]+(--(silent|location|fail|output)|-[a-z0-9]*[sflo]))/ && tolower($0) !~ /(127\.0\.0\.1|localhost|--cacert)/) {
          raw_fetch_hits = (raw_fetch_hits ? raw_fetch_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]])/ && !allow_pkg_next && $0 !~ /libscript-allow-raw-pkg/) {
        if (tolower($0) ~ /(^|[[:space:]&(])(call[[:space:]]+)?(winget[[:space:]]+(install|uninstall|upgrade)|choco[[:space:]]+(install|uninstall|upgrade)|scoop[[:space:]]+(install|uninstall|update))([[:space:]]|$)/) {
          raw_pkg_hits = (raw_pkg_hits ? raw_pkg_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]]|echo[[:space:]])/ && !allow_daemon_next && $0 !~ /libscript-allow-raw-daemon/) {
        if (tolower($0) ~ /(^|[[:space:]&(|])(sc\.exe[[:space:]]+(start|stop|create|delete|config|query|description)|sc[[:space:]]+(start|stop|create|delete|config|query|description)|net[[:space:]]+(start|stop)[[:space:]]+|systemctl[[:space:]]+(start|stop|restart|reload|daemon-reload|enable|disable|status|is-active)|rc-service[[:space:]]+|service[[:space:]]+[a-z0-9_$"\x27-]+[[:space:]]+(start|stop|restart|reload|status))([[:space:]]|$)/) {
          raw_daemon_hits = (raw_daemon_hits ? raw_daemon_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]]|echo[[:space:]])/ && !allow_sync_next && $0 !~ /libscript-allow-raw-sync/) {
        if (tolower($0) ~ /(^|[[:space:]&(|])(rsync[[:space:]]+-[a-z0-9-]+.*:|scp[[:space:]]+(-[a-z0-9]+[[:space:]]+)*[^[:space:]|&]+)[[:space:]]+/ && tolower($0) !~ /(gcloud[[:space:]]+(compute|storage)|vagrant[[:space:]]+rsync|cli\.(sh|cmd)[[:space:]"]*scp|:log_error|--version)/) {
          raw_sync_hits = (raw_sync_hits ? raw_sync_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]]|echo[[:space:]])/ && !allow_venv_next && $0 !~ /libscript-allow-raw-venv/) {
        if (tolower($0) ~ /(^|[[:space:]&(|])([a-z0-9_$"%!\\\/.:-]*python[0-9.]*(\.exe)?["!]?[[:space:]]+-m[[:space:]]+venv|uv(\.exe)?[[:space:]]+venv|virtualenv[[:space:]]+)/) {
          raw_venv_hits = (raw_venv_hits ? raw_venv_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]])/ && !allow_uuid_next && $0 !~ /libscript-allow-raw-uuid/) {
        if (tolower($0) ~ /guid\]::newguid[[:space:]]*\(/) {
          raw_uuid_hits = (raw_uuid_hits ? raw_uuid_hits "; " : "") FNR ":" $0
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]])/) {
        allow_fetch_next = 0; allow_pkg_next = 0; allow_daemon_next = 0;
        allow_sync_next = 0; allow_venv_next = 0; allow_uuid_next = 0;
      }
      if ($0 ~ /SCRIPT_DIR[%!][^\\\/"[:space:])]/) {
        script_dir_hits = (script_dir_hits ? script_dir_hits "; " : "") FNR ":" $0
      }
      if (index($0, "%~dp0\\") > 0) {
        dp0_double_bs_hits = (dp0_double_bs_hits ? dp0_double_bs_hits "; " : "") FNR ":" $0
      }
      if ($0 ~ /SCRIPT_DIR:~-1(%|!)""==""/ || $0 ~ /SCRIPT_DIR:~-1%"==""/ || index($0, "SCRIPT_DIR:~-1%\"==\"\\\\\"") > 0) {
        bad_script_dir_strip = (bad_script_dir_strip ? bad_script_dir_strip "; " : "") FNR ":" $0
      }
      if ($0 ~ /(LIBSCRIPT_ROOT_DIR|SCRIPT_DIR)[%!]\t/) {
        tab_path_hits = (tab_path_hits ? tab_path_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^endlocal[[:space:]]*&[[:space:]]*\(/) {
        in_endlocal = 1
      } else if (in_endlocal && $0 ~ /^[[:space:]]*\)/) {
        in_endlocal = 0
      } else if (in_endlocal && $0 ~ /!PATH!/) {
        endlocal_delayed_hits = (endlocal_delayed_hits ? endlocal_delayed_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^[[:space:]]+endlocal[[:space:]]*&&?[[:space:]]*(\(|set[[:space:]])/) {
        endlocal_delayed_hits = (endlocal_delayed_hits ? endlocal_delayed_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$))/ && tolower($0) ~ /(^|[[:space:](&])for[[:space:]]+\/r[[:space:]]+[^%]*![a-z0-9_]+!/) {
        for_r_delayed_hits = (for_r_delayed_hits ? for_r_delayed_hits "; " : "") FNR ":" $0
      }
      if (tolower($0) ~ /^[[:space:]]*setlocal[[:space:]]+enabledelayedexpansion([[:space:]]|$)/) {
        del_exp_active = 1
      } else if (tolower($0) ~ /^[[:space:]]*setlocal[[:space:]]+(disable)(delayed)(expansion)([[:space:]]|$)/) {
        del_exp_active = 0
      }
      if (del_exp_active && index($0, "^^!") > 0 && tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$))/) {
        in_q = 0
        for (qi = 1; qi <= length($0); qi++) {
          qc = substr($0, qi, 1)
          if (!in_q) {
            if (qc == "^") { qi++; continue }
            if (qc == "\"") { in_q = 1 }
          } else {
            if (qc == "\"") { in_q = 0 }
            else if (substr($0, qi, 3) == "^^!") {
              quoted_dbl_caret_bang_hits = (quoted_dbl_caret_bang_hits ? quoted_dbl_caret_bang_hits "; " : "") FNR ":" $0
              break
            }
          }
        }
      }
      if (prev_open_paren && $0 ~ /^[[:space:]]*\)[[:space:]]*$/) {
        empty_paren_hits = (empty_paren_hits ? empty_paren_hits "; " : "") "lines " prev_open_ln "-" FNR
        prev_open_paren = 0
      } else if ($0 ~ /\([[:space:]]*$/ && tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$)|echo([[:space:].]|$))/) {
        prev_open_paren = 1
        prev_open_ln = FNR
      } else if ($0 !~ /^[[:space:]]*$/ && tolower($0) !~ /^[[:space:]]*(::|rem([[:space:]]|$))/) {
        prev_open_paren = 0
      }
      match($0, /^[[:space:]]*/)
      ind = RLENGTH
      if (tolower($0) ~ /^[[:space:]]*[)][[:space:]]*else([[:space:]]|$)/ && (ind in chained_if)) {
        chained_if_else_hits = (chained_if_else_hits ? chained_if_else_hits "; " : "") chained_if[ind] "->" FNR ":" $0
        delete chained_if[ind]
      } else if (tolower($0) ~ /^[[:space:]]*[)][[:space:]]*$/) {
        delete chained_if[ind]
      }
      if (tolower($0) ~ /^[[:space:]]*([)][[:space:]]*else[[:space:]]+)?if[[:space:]].*[[:space:]]if[[:space:]].*[(][[:space:]]*$/ && tolower($0) !~ /powershell|python|jq|sqlite3/) {
        chained_if[ind] = FNR
      }
      if ($0 ~ /^[[:space:]]*:[A-Za-z0-9_.-]+/) {
        lbl = $0
        sub(/^[[:space:]]*:/, "", lbl)
        sub(/[^A-Za-z0-9_.-].*$/, "", lbl)
        if (lbl != "") {
          lbl_l = tolower(lbl)
          if (lbl_l in defined_labels) {
            dup_label_hits = (dup_label_hits ? dup_label_hits "; " : "") FNR ":" lbl
          }
          defined_labels[lbl_l] = 1
        }
      }
      if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]])/ && tolower($0) !~ /echo[[:space:]]/) {
        line_lc = tolower($0)
        if (match(line_lc, /(^|[[:space:](&])goto[[:space:]]+:?[a-z0-9_.-]+([[:space:])&]|$)/)) {
          g_tok = substr(line_lc, RSTART, RLENGTH)
          sub(/^.*goto[[:space:]]+:?/, "", g_tok)
          sub(/[^a-z0-9_.-].*$/, "", g_tok)
          if (g_tok != "" && g_tok != "eof" && index($0, "%") == 0 && index($0, "!") == 0) {
            goto_targets[FNR] = g_tok
          }
        }
        if (match(line_lc, /(^|[[:space:](&])call[[:space:]]+:[a-z0-9_.-]+([[:space:])&]|$)/)) {
          c_tok = substr(line_lc, RSTART, RLENGTH)
          sub(/^.*call[[:space:]]+:/, "", c_tok)
          sub(/[^a-z0-9_.-].*$/, "", c_tok)
          if (c_tok != "" && c_tok != "eof") {
            call_targets[FNR] = c_tok
          }
        }
      }
    }
    END {
      if (prev_file != "") flush_cmd(prev_file)
    }
  ' "$@" 2>/dev/null || true)

  if [ -n "$_cmd_out" ]; then
    OIFS_C="$IFS"
    IFS='
'
    for _cl in $_cmd_out; do
      _cf="${_cl%%|*}"
      _crest="${_cl#*|}"
      _cr="${_crest%%|*}"
      _cm="${_crest#*|}"
      report_cmd_violation "$_cf" "$_cr" "$_cm"
    done
    IFS="$OIFS_C"
  fi
}

# shellcheck disable=SC2329
# ## audit_json_batch
# Validates JSON syntax, manifest OS identifiers, and schema property descriptions in batched jq invocations.
audit_json_batch() {
  [ "$#" -gt 0 ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  if ! jq empty "$@" >/dev/null 2>&1; then
    for _ajb_f in "$@"; do
      if ! jq empty "$_ajb_f" >/dev/null 2>&1; then
        log_failure "$_ajb_f" 'JSON_VALIDITY' 'File is not syntactically valid JSON.'
      fi
    done
  fi
}

# shellcheck disable=SC2329
# ## audit_manifest_batch
# Validates OS whitelist/blacklist identifiers across a batch of _lib/*/*/manifest.json files in one jq invocation.
audit_manifest_batch() {
  [ "$#" -gt 0 ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  _amb_out=$(jq -r '
    input_filename as $f
    | ((.os_whitelist // []) + (.os_blacklist // []))[]
    | select(test("^(all|linux|macos|darwin|mac|windows|msdos|dos|freebsd|openbsd|netbsd|dragonfly|bsd|sunos|illumos|solaris|reactos|alpine|debian|ubuntu|rhel|fedora|centos|rocky|almalinux|arch|artix|manjaro|gentoo|void|suse|opensuse|solus|clearlinux|nixos)$") | not)
    | "\($f)|\(.)"
  ' "$@" 2>/dev/null || true)

  if [ -n "$_amb_out" ]; then
    OIFS_M="$IFS"
    IFS='
'
    for _ml in $_amb_out; do
      _mf="${_ml%%|*}"
      _mos="${_ml#*|}"
      log_failure "$_mf" 'JSON_VALIDITY' "Invalid OS identifier in manifest.json: $_mos"
    done
    IFS="$OIFS_M"
  fi
}

# shellcheck disable=SC2329
# ## audit_schema_batch
# Validates 100% property description coverage across a batch of *.schema.json files in one jq invocation.
audit_schema_batch() {
  [ "$#" -gt 0 ] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  _asb_out=$(jq -r '
    def check_props:
      if type == "object" then
        (if has("properties") and (.properties | type == "object") then
          .properties | to_entries[] |
          (if (.value | type == "object") and ((.value | has("description")) | not) then
            .key
          else
            empty
          end),
          (.value | check_props)
        else
          empty
        end),
        (to_entries[] | .value | check_props)
      elif type == "array" then
        .[] | check_props
      else
        empty
      end;
    input_filename as $f
    | [check_props] | if length > 0 then "\($f)|\(join(" "))" else empty end
  ' "$@" 2>/dev/null || true)

  if [ -n "$_asb_out" ]; then
    OIFS_J="$IFS"
    IFS='
'
    for _jl in $_asb_out; do
      _jf="${_jl%%|*}"
      _json_keys="${_jl#*|}"
      log_failure "$_jf" 'SCHEMA_DESCRIPTIONS' "Missing property description(s): $_json_keys"
    done
    IFS="$OIFS_J"
  fi
}

# shellcheck disable=SC2329
# ## audit_checksums_file
# Validates SHA256 formatting and duplicate-entry consistency in _lib/checksums.txt.
audit_checksums_file() {
  _acf_f="$1"
  _cs_err=$(awk '
    /^[[:space:]]*#/ || NF == 0 { next }
    NF != 2 || $2 !~ /^[0-9a-fA-F]{64}$/ { print "line " NR ": malformed entry"; next }
    {
      if (($1 in seen) && seen[$1] != tolower($2)) {
        print "line " NR ": conflicting SHA256 for " $1
      }
      seen[$1] = tolower($2)
    }
  ' "$_acf_f" 2>/dev/null || true)
  if [ -n "$_cs_err" ]; then
    log_failure "$_acf_f" 'CHECKSUM_INTEGRITY' "Invalid checksum entry: $_cs_err"
  fi
}

# shellcheck disable=SC2329
# ## normalize_candidate_path
# Resolves a candidate path relative to REPO_ROOT when located inside the repository.
normalize_candidate_path() {
  raw_file="$1"
  case "$raw_file" in
    "${REPO_ROOT}/"*|"${REPO_ROOT}\\"*)
      file="${raw_file#"${REPO_ROOT}"?}"
      file="${file#./}"
      ;;
    /*|[A-Za-z]:[\\/]*)
      file="$raw_file"
      if _asf_dir=$(cd -- "$(dirname -- "$raw_file")" 2>/dev/null && pwd); then
        _asf_abs="${_asf_dir}/$(basename -- "$raw_file")"
        case "$_asf_abs" in
          "${REPO_ROOT}/"*)
            file="${_asf_abs#"${REPO_ROOT}/"}"
            file="${file#./}"
            ;;
        esac
      fi
      ;;
    *)
      file="${raw_file#./}"
      ;;
  esac
  printf '%s\n' "$file"
}

# shellcheck disable=SC2329
# ## audit_shard_worker
# Processes a shard file of candidate paths using batched multi-file awk and jq passes.
audit_shard_worker() {
  _asw_shard="$1"
  ERRORS=0
  _asw_dir=$(libscript_make_tmpdir 'asw')
  _asw_sh="${_asw_dir}/SH.TXT"
  _asw_cmd="${_asw_dir}/CMD.TXT"
  _asw_ps1="${_asw_dir}/PS1.TXT"
  _asw_json="${_asw_dir}/JSON.TXT"
  _asw_man="${_asw_dir}/MAN.TXT"
  _asw_sch="${_asw_dir}/SCH.TXT"
  : > "$_asw_sh"
  : > "$_asw_cmd"
  : > "$_asw_ps1"
  : > "$_asw_json"
  : > "$_asw_man"
  : > "$_asw_sch"

  _asw_cs="${_asw_dir}/CS.TXT"
  : > "$_asw_cs"
  if ! ASW_ROOT="${REPO_ROOT}" ASW_EXPLICIT="${LIBSCRIPT_AUDIT_EXPLICIT:-0}" ASW_DIR="${_asw_dir}" awk '
    BEGIN {
      root = ENVIRON["ASW_ROOT"]
      gsub(/\\/, "/", root)
      sub(/\/+$/, "", root)
      is_explicit = ENVIRON["ASW_EXPLICIT"]
      d = ENVIRON["ASW_DIR"]
      gsub(/\\/, "/", d)
      sub(/\/+$/, "", d)
    }
    NF == 0 { next }
    {
      f = $0
      sub(/\r$/, "", f)
      gsub(/\\/, "/", f)
      slash_root = root "/"
      if (root != "" && index(f, slash_root) == 1) f = substr(f, length(slash_root) + 1)
      sub(/^\.\//, "", f)
      if (f ~ /(^|\/)\.git\//) next
      if (is_explicit != "1" && f ~ /(^|\/)(\.git|gen|cache|tmp|tests_tmp|node_modules|\.vagrant|\.venv|venv|dist|build|\.angular|\.gradle)\//) next
      if (f == ".githooks/pre-commit" || f ~ /\/\.githooks\/pre-commit$/ || f ~ /\.sh$/) {
        print f >> (d "/SH.TXT")
      } else if (f ~ /\.(cmd|bat)$/) {
        print f >> (d "/CMD.TXT")
      } else if (f ~ /\.ps1$/) {
        print f >> (d "/PS1.TXT")
      } else if (f ~ /\.json$/) {
        print f >> (d "/JSON.TXT")
        if (f ~ /^_lib\/[^\/]+\/[^\/]+\/manifest\.json$/) print f >> (d "/MAN.TXT")
        if (f ~ /\.schema\.json$/) print f >> (d "/SCH.TXT")
      } else if (f == "_lib/checksums.txt") {
        print f >> (d "/CS.TXT")
      }
    }
  ' "$_asw_shard"; then
    rm -rf "$_asw_dir"
    return 1
  fi
  for _asw_list_f in "$_asw_sh" "$_asw_cmd" "$_asw_ps1" "$_asw_json" "$_asw_man" "$_asw_sch"; do
    if [ -s "$_asw_list_f" ]; then
      while IFS= read -r _asw_chk || [ -n "$_asw_chk" ]; do
        if [ -f "$_asw_chk" ]; then
          printf '%s\n' "$_asw_chk"
        fi
      done < "$_asw_list_f" > "${_asw_list_f}.ok"
      mv -f "${_asw_list_f}.ok" "$_asw_list_f"
    fi
  done
  if [ -s "$_asw_cs" ]; then
    while IFS= read -r _cs_f || [ -n "$_cs_f" ]; do
      [ -f "$_cs_f" ] && audit_checksums_file "$_cs_f"
    done < "$_asw_cs"
  fi

  if [ -s "$_asw_sh" ]; then
    libscript_batch_exec "$_asw_sh" 200 audit_sh_batch
  fi
  if [ -s "$_asw_ps1" ]; then
    libscript_batch_exec "$_asw_ps1" 200 audit_ps1_batch
  fi
  if [ -s "$_asw_cmd" ]; then
    libscript_batch_exec "$_asw_cmd" 200 audit_cmd_batch
  fi
  if [ -s "$_asw_json" ]; then
    libscript_batch_exec "$_asw_json" 200 audit_json_batch
  fi
  if [ -s "$_asw_man" ]; then
    libscript_batch_exec "$_asw_man" 200 audit_manifest_batch
  fi
  if [ -s "$_asw_sch" ]; then
    libscript_batch_exec "$_asw_sch" 200 audit_schema_batch
  fi

  rm -rf "$_asw_dir"
  if [ "$ERRORS" -gt 0 ]; then
    return 1
  fi
  return 0
}

# ## audit_gitattributes_eol
# Verifies via git check-attr and git ls-files --eol that tracked scripts resolve to expected line endings without index/worktree CR corruption.
audit_gitattributes_eol() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi
  _eol_violations=$(
    git ls-files --cached --others --exclude-standard '*.sh' '*.ps1' '*.cmd' '*.bat' '.githooks/pre-commit' 2>/dev/null \
      | git check-attr --stdin eol 2>/dev/null \
      | awk -F': eol: ' '
        NF == 2 {
          path = $1
          val = $2
          sub(/\r$/, "", val)
          if (path ~ /\.(cmd|bat)$/) {
            if (val != "crlf") {
              print path "|Expected git attribute eol=crlf for Windows Batch script, found eol=" val
            }
          } else {
            if (val != "lf") {
              print path "|Expected git attribute eol=lf for script, found eol=" val
            }
          }
        }
      ' || true
  )
  if [ -n "$_eol_violations" ]; then
    OIFS_E="$IFS"
    IFS='
'
    for _ev in $_eol_violations; do
      _ep="${_ev%%|*}"
      _em="${_ev#*|}"
      log_failure "$_ep" 'GITATTRIBUTES_EOL' "$_em"
    done
    IFS="$OIFS_E"
  fi
  _idx_eol_hits=$(
    git ls-files --eol '*.sh' '*.ps1' '*.cmd' '*.bat' '.githooks/pre-commit' 2>/dev/null \
      | awk -F'\t' '
        NF == 2 {
          meta = $1
          path = $2
          split(meta, m, /[[:space:]]+/)
          i_eol = m[1]
          w_eol = m[2]
          if (w_eol == "w/-text") {
            print path "|w_text|Working-tree script contains lone CR or binary bytes (w/-text)"
          } else if (i_eol == "i/mixed" || i_eol == "i/crlf") {
            print path "|idx_mixed|Git index blob has unnormalized line endings (" i_eol "); renormalize to i/lf"
          }
        }
      ' || true
  )
  if [ -n "$_idx_eol_hits" ]; then
    OIFS_E="$IFS"
    IFS='
'
    for _ih in $_idx_eol_hits; do
      _ip="${_ih%%|*}"
      _i_rest="${_ih#*|}"
      _i_kind="${_i_rest%%|*}"
      _i_msg="${_i_rest#*|}"
      if [ "$_i_kind" = 'w_text' ] || git diff --quiet -- "$_ip" 2>/dev/null; then
        log_failure "$_ip" 'GITATTRIBUTES_EOL' "$_i_msg"
      fi
    done
    IFS="$OIFS_E"
  fi
}

# ## audit_repo_global_invariants
# Runs repository-wide SOURCE_CONTEXT_SAFETY, CLI_VERB_PARITY, and batched _lib/*/* contract checks in --all mode.
audit_repo_global_invariants() {
  set +f
  for _src_lib in engine/common/*.sh _lib/*/_common/*.sh experiments/_common/*.sh; do
    [ -f "$_src_lib" ] || continue
    if ! grep -qE 'THIS_FILE="\$\{?_[A-Za-z0-9_]+' "$_src_lib"; then
      log_failure "$_src_lib" 'SOURCE_CONTEXT_SAFETY' 'Sourced _common library must save and restore caller THIS_FILE / SCRIPT_DIR.'
    fi
  done

  for _eng_pair in \
    'infrastructure/clusters/engine:up status scale drain failover upgrade destroy' \
    'workloads/constellations/engine:up status scale drain failover upgrade destroy' \
    'workloads/engine:compile submit status logs stop destroy' \
    'traits/engine:list enable disable apply verify teardown' \
    'experiments/engine:list scaffold validate run render-latex update-readme'; do
    _ep_base="${_eng_pair%%:*}"
    _ep_verbs="${_eng_pair#*:}"
    if [ -f "${_ep_base}.sh" ] && [ -f "${_ep_base}.cmd" ]; then
      for _v in $_ep_verbs; do
        if ! awk -v v="$_v" '
          { sub(/\r$/, "", $0); l = tolower($0) }
          l ~ /^[[:space:]]*(::|rem([[:space:]]|$))/ { next }
          l ~ /^[[:space:]]*echo[[:space:]]+usage:/ { next }
          index(l, tolower(v)) > 0 { found = 1 }
          END { exit(found ? 0 : 1) }
        ' "${_ep_base}.cmd"; then
          log_failure "${_ep_base}.cmd" 'CLI_VERB_PARITY' "Missing subcommand '${_v}' dispatch present in ${_ep_base}.sh."
        fi
      done
    fi
  done

  _cap_dir=$(libscript_make_tmpdir 'caps')
  _cap_map="${_cap_dir}/CAPS.TSV"
  : > "$_cap_map"
  if command -v jq >/dev/null 2>&1 && [ -d '_lib' ]; then
    find _lib -mindepth 3 -maxdepth 3 -name 'manifest.json' -exec jq -r '
      "\(input_filename)\t \([.capabilities[]? // empty] | join(" ")) "
    ' {} + > "$_cap_map" 2>/dev/null || true
  fi

  for cat_dir in _lib/*; do
    [ -d "$cat_dir" ] || continue
    [ "$(basename "$cat_dir")" = '_common' ] && continue
    for comp_dir in "$cat_dir"/*; do
      [ -d "$comp_dir" ] || continue
      [ "$(basename "$comp_dir")" = '_common' ] && continue
      case "$comp_dir" in
        _lib/*/*-suite)
          log_failure "$comp_dir" 'EXP_IN_LIB' 'Empirical campaign suites belong in experiments/<suite-id>/, not inside _lib/.'
          ;;
      esac
      if [ -d "$comp_dir/suites" ]; then
        log_failure "$comp_dir" 'EXP_IN_LIB' "Empirical subsuites belong in experiments/<suite-id>/, not inside $comp_dir/suites/."
      fi
      for req_file in cli.sh cli.cmd test.sh test.cmd manifest.json vars.schema.json README.md; do
        if [ ! -f "$comp_dir/$req_file" ]; then
          log_failure "$comp_dir" 'VERSION_MANAGER_CONTRACT' "Missing required Version Manager Contract file: $req_file"
        fi
      done
    done
  done
  set -f

  if [ -s "$_cap_map" ]; then
    while IFS='	' read -r _mf_path _as_caps; do
      [ -n "$_mf_path" ] || continue
      comp_dir="${_mf_path%/manifest.json}"
      case "$_as_caps" in
        *' userland-package '*|*' sysroot-package '*)
          for req_file in setup.sh setup.cmd env.sh env.cmd uninstall.sh uninstall.cmd; do
            if [ ! -f "$comp_dir/$req_file" ]; then
              log_failure "$comp_dir" 'VERSION_MANAGER_CONTRACT' "Missing required package lifecycle file: $req_file"
            fi
          done
          ;;
      esac
      case "$_as_caps" in
        *' service-daemon '*)
          for req_file in service.sh service.cmd; do
            if [ ! -f "$comp_dir/$req_file" ]; then
              log_failure "$comp_dir" 'VERSION_MANAGER_CONTRACT' "Missing required service-daemon file: $req_file"
            fi
          done
          ;;
        *)
          for forbid_file in service.sh service.cmd; do
            if [ -f "$comp_dir/$forbid_file" ]; then
              log_failure "$comp_dir/$forbid_file" 'VERSION_MANAGER_CONTRACT' "Component defines $forbid_file without 'service-daemon' in manifest.json."
            fi
          done
          ;;
      esac
    done < "$_cap_map"
  fi
  rm -rf "$_cap_dir"
}

if [ "${1:-}" = '--all' ]; then
  audit_gitattributes_eol
  _as_tmp_dir=$(libscript_make_tmpdir 'all')
  _all_candidates="${_as_tmp_dir}/CANDIDATES.TXT"
  git ls-files --cached --others --exclude-standard '*.sh' '*.cmd' '*.bat' '*.ps1' '*.json' '_lib/checksums.txt' '.githooks/pre-commit' > "$_all_candidates"
  LIBSCRIPT_AUDIT_EXPLICIT=0
  export LIBSCRIPT_AUDIT_EXPLICIT
  if [ -s "$_all_candidates" ]; then
    if ! libscript_parallel_shards "$_all_candidates" audit_shard_worker; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
  rm -rf "$_as_tmp_dir"
  audit_repo_global_invariants
elif [ "${1:-}" = '--staged' ] || [ "$#" -eq 0 ]; then
  _as_tmp_dir=$(libscript_make_tmpdir 'staged')
  _staged_tmp="${_as_tmp_dir}/STAGED.TXT"
  git diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM > "$_staged_tmp" || true
  if [ ! -s "$_staged_tmp" ]; then
    rm -rf "$_as_tmp_dir"
    printf '%s\n' '[AUDIT] No matching files to audit.'
    exit 0
  fi
  if grep -Eq '(\.gitattributes|\.githooks/pre-commit)$' "$_staged_tmp"; then
    audit_gitattributes_eol
  fi
  LIBSCRIPT_AUDIT_EXPLICIT=0
  export LIBSCRIPT_AUDIT_EXPLICIT
  if ! libscript_parallel_shards "$_staged_tmp" audit_shard_worker; then
    ERRORS=$((ERRORS + 1))
  fi
  rm -rf "$_as_tmp_dir"
else
  _as_tmp_dir=$(libscript_make_tmpdir 'explicit')
  _exp_tmp="${_as_tmp_dir}/EXP.TXT"
  : > "$_exp_tmp"
  for candidate in "$@"; do
    case "$candidate" in
      *.gitattributes|*.githooks/pre-commit) audit_gitattributes_eol ;;
    esac
    case "$candidate" in
      /*|[A-Za-z]:[\\/]*)
        if [ -f "$candidate" ]; then
          printf '%s\n' "$candidate" >> "$_exp_tmp"
        fi
        ;;
      *)
        if [ -f "${ORIG_PWD}/${candidate}" ]; then
          printf '%s\n' "${ORIG_PWD}/${candidate}" >> "$_exp_tmp"
        elif [ -f "$candidate" ]; then
          printf '%s\n' "$candidate" >> "$_exp_tmp"
        fi
        ;;
    esac
  done
  LIBSCRIPT_AUDIT_EXPLICIT=1
  export LIBSCRIPT_AUDIT_EXPLICIT
  if [ -s "$_exp_tmp" ]; then
    if ! libscript_parallel_shards "$_exp_tmp" audit_shard_worker; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
  rm -rf "$_as_tmp_dir"
fi

_total_violations=$(awk 'END { print NR + 0 }' "$AS_ERR_LOG" 2>/dev/null || printf '0\n')
rm -rf "$AS_ERR_DIR"
if [ "$_total_violations" -gt 0 ]; then
  ERRORS="$_total_violations"
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[AUDIT] %d standards violation(s) found.\n' "$ERRORS" >&2
  exit 1
fi

printf '%s\n' '[AUDIT] All inspected files adhere to LibScript engineering standards.'
exit 0
