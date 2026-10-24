#!/bin/sh
# ## Overview
# Audits codebase and staged files for adherence to LibScript engineering standards:
# - POSIX /bin/sh usage and canonical THIS_FILE preamble
# - Windows batch script parity (.cmd / .bat)
# - No evil eval usage
# - Idempotency patterns
# - 100% doc block coverage (## Overview and ## Usage)
#
# ## Usage
# Execute this script to audit files:
#   ./devtools/audit/audit_standards.sh [--all | --staged | <file>...]

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage and help information for the audit tool.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [--all | --staged | <file>...]"
  printf '%s\n' "Audits files for adherence to LibScript engineering standards."
  printf '
'
  printf '%s\n' "Options:"
  printf '%s\n' "  --all               Audit all tracked script files in repository."
  printf '%s\n' "  --staged            Audit git-staged files (default if no files given)."
  printf '%s\n' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

cd "$REPO_ROOT"

# ## handle_interrupt
# Signal handler to abort audit immediately on interruption.
# shellcheck disable=SC2329
handle_interrupt() {
  trap - INT TERM HUP EXIT
  exit 130
}

trap 'handle_interrupt' INT TERM HUP

ERRORS=0

# ## log_failure
# Records and outputs an audit violation message.
log_failure() {
  target_file="$1"
  rule_name="$2"
  details="$3"
  printf '[STANDARDS VIOLATION] [%s] %s: %s\n' "$rule_name" "$target_file" "$details" >&2
  ERRORS=$((ERRORS + 1))
}

# ## is_excluded_path
# Checks whether a given path should be skipped from audits.
is_excluded_path() {
  check_path="$1"
  case "$check_path" in
    .git/*|gen/*|cache/*|tmp/*|tests_tmp/*|node_modules/*|vagrant/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ## audit_single_file
# Runs all static standard checks on an individual file.
audit_single_file() {
  file="$1"

  if [ ! -f "$file" ]; then
    return 0
  fi

  if is_excluded_path "$file"; then
    return 0
  fi

  ext="${file##*.}"

  # 1. POSIX /bin/sh, THIS_FILE dance, idempotency, eval, and doc header (for .sh files)
  if [ "$ext" = "sh" ]; then
    sh_violations=$(awk '
      BEGIN {
        in_heredoc = 0; delim = ""; shebang_count = 0; shebang_lines = "";
        has_this_file = 0; has_stack = 0; has_root_dir = 0; has_zsh_eval = 0;
        has_overview = 0; has_usage = 0;
        mkdir_hits = ""; ln_hits = ""; eval_hits = ""; git_push_hits = "";
      }
      NR == 1 {
        first_line = $0
      }
      NR <= 30 {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      NR <= 45 {
        if ($0 ~ /THIS_FILE=/) has_this_file = 1
        if ($0 ~ /STACK/) has_stack = 1
        if ($0 ~ /LIBSCRIPT_ROOT_DIR/) has_root_dir = 1
        if ($0 ~ /# libscript-allow-eval/) has_zsh_eval = 1
      }
      {
        if (in_heredoc) {
          cur = $0
          sub(/^[[:space:]]+/, "", cur)
          sub(/[[:space:]]+$/, "", cur)
          if (cur == delim) {
            in_heredoc = 0
            delim = ""
          }
          next
        }
        idx = index($0, "<<")
        if (idx > 0) {
          rest = substr($0, idx + 2)
          sub(/^[ -]+/, "", rest)
          sub(/["\x27]/, "", rest)
          sub(/["\x27].*$/, "", rest)
          sub(/[[:space:]].*$/, "", rest)
          if (rest != "") {
            in_heredoc = 1
            delim = rest
          }
        }
        if ($0 ~ /^#!/) {
          shebang_count++
          shebang_lines = (shebang_lines ? shebang_lines ", " : "") NR
        }
        if ($0 ~ /^[[:space:]]*mkdir[[:space:]]+[^-]/ && tolower($0) !~ /lock|while|if[[:space:]]+!/) {
          mkdir_hits = (mkdir_hits ? mkdir_hits "; " : "") NR ":" $0
        }
        if ($0 ~ /^[[:space:]]*ln[[:space:]]+-s[[:space:]]+[^-]/) {
          ln_hits = (ln_hits ? ln_hits "; " : "") NR ":" $0
        }
        if (($0 ~ /^[[:space:]]*eval([[:space:]]|$)/ || $0 ~ /;[[:space:]]*eval([[:space:]]|$)/) && $0 !~ /libscript-allow-eval/) {
          eval_hits = (eval_hits ? eval_hits "; " : "") NR ":" $0
        }
        if ($0 ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
          git_push_hits = (git_push_hits ? git_push_hits "; " : "") NR ":" $0
        }
      }
      END {
        if (first_line ~ /bash|zsh|ksh/) {
          print "POSIX_SHEBANG|Non-POSIX shebang found: " first_line ". LibScript requires #!/bin/sh."
        } else if (first_line !~ /^#!\/bin\/sh/) {
          print "MISSING_SHEBANG|Missing #!/bin/sh shebang on line 1."
        }
        if (shebang_count > 1) {
          print "DUPLICATE_SHEBANG|Multiple shebangs found outside of heredocs at lines: " shebang_lines "."
        }
        if (!has_this_file) print "THIS_FILE_DANCE|Missing canonical THIS_FILE= resolution in first 30 lines."
        if (!has_stack) print "RECURSION_GUARD|Missing STACK recursion guard in first 35 lines."
        if (!has_root_dir) print "ROOT_DIR_RESOLUTION|Missing LIBSCRIPT_ROOT_DIR resolution in header."
        if (!has_zsh_eval) print "ZSH_ALLOW_EVAL_TAG|Missing # libscript-allow-eval in ZSH_VERSION header block."
        if (!has_overview) print "DOC_OVERVIEW|Missing doc block ## Overview in first 30 lines."
        if (!has_usage) print "DOC_USAGE|Missing doc block ## Usage in first 30 lines."
        if (mkdir_hits != "") print "IDEMPOTENCY|Unguarded mkdir found without -p: " mkdir_hits
        if (ln_hits != "") print "IDEMPOTENCY|Unguarded ln -s found without -f: " ln_hits
        if (eval_hits != "") print "BAN_EVAL|Disallowed use of eval found: " eval_hits
        if (git_push_hits != "") print "REMOTE_SAFETY|Strict safety violation: found git push invocation: " git_push_hits
      }
    ' "$file" 2>/dev/null || true)

    if [ -n "$sh_violations" ]; then
      OIFS_V="$IFS"
      IFS='
'
      for v_line in $sh_violations; do
        v_rule="${v_line%%|*}"
        v_msg="${v_line#*|}"
        case "$v_rule" in
          MISSING_SHEBANG)
            case "$file" in
              *.tpl|*.template|*docker*|*test*|*docs-web-template*) ;;
              *) log_failure "$file" "POSIX_SHEBANG" "$v_msg" ;;
            esac
            ;;
          THIS_FILE_DANCE|RECURSION_GUARD|ROOT_DIR_RESOLUTION|ZSH_ALLOW_EVAL_TAG)
            case "$file" in
              *Dockerfile*|*.tpl|*dockerfiles-ssh*|*docker/*) ;;
              *) log_failure "$file" "$v_rule" "$v_msg" ;;
            esac
            ;;
          *)
            log_failure "$file" "$v_rule" "$v_msg"
            ;;
        esac
      done
      IFS="$OIFS_V"
    fi

    # 2. Windows batch parity (.cmd or .bat equivalent)
    case "$file" in
      docker/*|dockerfiles-ssh/*|*.tpl|*Vagrantfile*)
        ;;
      *)
        cmd_equiv="${file%.sh}.cmd"
        bat_equiv="${file%.sh}.bat"
        if [ ! -f "$cmd_equiv" ] && [ ! -f "$bat_equiv" ]; then
          log_failure "$file" "WINDOWS_PARITY" "Missing Windows batch equivalent file ('$cmd_equiv')."
        fi
        ;;
    esac
  fi

  # Validate .ps1 companion parity (.sh and .cmd equivalents) and checks
  if [ "$ext" = "ps1" ]; then
    sh_equiv="${file%.ps1}.sh"
    cmd_equiv="${file%.ps1}.cmd"
    if [ ! -f "$sh_equiv" ]; then
      log_failure "$file" "POSIX_PARITY" "Missing POSIX shell equivalent file ('$sh_equiv') for PowerShell script."
    fi
    if [ ! -f "$cmd_equiv" ]; then
      log_failure "$file" "WINDOWS_PARITY" "Missing Windows batch equivalent file ('$cmd_equiv') for PowerShell script."
    fi
    ps1_violations=$(awk '
      BEGIN { has_overview = 0; has_usage = 0; eval_hits = ""; git_push_hits = "" }
      { sub(/\r$/, "", $0) }
      NR <= 30 {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      {
        if (tolower($0) ~ /^[[:space:]]*(invoke-expression|iex)([[:space:]]|$)/ && $0 !~ /libscript-allow-eval/) {
          eval_hits = (eval_hits ? eval_hits "; " : "") NR ":" $0
        }
        if (tolower($0) ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
          git_push_hits = (git_push_hits ? git_push_hits "; " : "") NR ":" $0
        }
      }
      END {
        if (!has_overview) print "DOC_OVERVIEW|Missing doc block ## Overview in first 30 lines."
        if (!has_usage) print "DOC_USAGE|Missing doc block ## Usage in first 30 lines."
        if (eval_hits != "") print "BAN_EVAL|Disallowed use of Invoke-Expression found: " eval_hits
        if (git_push_hits != "") print "REMOTE_SAFETY|Strict safety violation: found git push invocation: " git_push_hits
      }
    ' "$file" 2>/dev/null || true)
    if [ -n "$ps1_violations" ]; then
      OIFS_V="$IFS"
      IFS='
'
      for v_line in $ps1_violations; do
        log_failure "$file" "${v_line%%|*}" "${v_line#*|}"
      done
      IFS="$OIFS_V"
    fi
  fi

  # Validate Windows batch headers, idempotency, docstrings, and safety in single awk pass
  if [ "$ext" = "cmd" ] || [ "$ext" = "bat" ]; then
    cmd_violations=$(awk '
      BEGIN {
        has_echo_off = 0; has_delayed = 0; has_this_file = 0;
        has_overview = 0; has_usage = 0; has_dup_stack = 0;
        mkdir_hits = ""; git_push_hits = ""; script_dir_hits = ""; chained_if_else_hits = "";
      }
      { sub(/\r$/, "", $0) }
      NR == 1 {
        if (tolower($0) == "@echo off") has_echo_off = 1
      }
      NR <= 25 {
        if (tolower($0) ~ /enabledelayedexpansion/) has_delayed = 1
        if (tolower($0) ~ /this_file=%~f0/) has_this_file = 1
      }
      NR <= 30 {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      {
        if (tolower($0) ~ /searchval=;%this_file%;/) has_dup_stack = 1
        if (tolower($0) ~ /^[[:space:]]*(mkdir|md)[[:space:]]+/ && tolower($0) !~ /if[[:space:]]+not[[:space:]]+exist/) {
          mkdir_hits = (mkdir_hits ? mkdir_hits "; " : "") NR ":" $0
        }
        if (tolower($0) ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
          git_push_hits = (git_push_hits ? git_push_hits "; " : "") NR ":" $0
        }
        if ($0 ~ /SCRIPT_DIR[%!][^\\/"[:space:]\)]/) {
          script_dir_hits = (script_dir_hits ? script_dir_hits "; " : "") NR ":" $0
        }
        match($0, /^[[:space:]]*/)
        ind = RLENGTH
        if (tolower($0) ~ /^[[:space:]]*[)][[:space:]]*else([[:space:]]|$)/ && (ind in chained_if)) {
          chained_if_else_hits = (chained_if_else_hits ? chained_if_else_hits "; " : "") chained_if[ind] "->" NR ":" $0
          delete chained_if[ind]
        } else if (tolower($0) ~ /^[[:space:]]*[)][[:space:]]*$/) {
          delete chained_if[ind]
        }
        if (tolower($0) ~ /^[[:space:]]*([)][[:space:]]*else[[:space:]]+)?if[[:space:]].*[[:space:]]if[[:space:]].*[(][[:space:]]*$/ && tolower($0) !~ /powershell|python|jq|sqlite3/) {
          chained_if[ind] = NR
        }
      }
      END {
        if (!has_echo_off) print "BATCH_ECHO_OFF|Missing @echo off on line 1."
        if (!has_delayed) print "BATCH_DELAYED_EXPANSION|Missing setlocal EnableDelayedExpansion in first 25 lines (before :find_root)."
        if (!has_this_file) print "BATCH_THIS_FILE|Missing set \"THIS_FILE=%~f0\" in first 25 lines."
        if (has_dup_stack) print "BATCH_DUPLICATE_STACK|Duplicate legacy searchVal=;%THIS_FILE%; STACK block found."
        if (!has_overview) print "DOC_OVERVIEW|Missing doc block ## Overview in first 30 lines."
        if (!has_usage) print "DOC_USAGE|Missing doc block ## Usage in first 30 lines."
        if (mkdir_hits != "") print "IDEMPOTENCY|Unguarded mkdir in batch script: " mkdir_hits
        if (git_push_hits != "") print "REMOTE_SAFETY|Strict safety violation: found git push invocation: " git_push_hits
        if (script_dir_hits != "") print "BATCH_SCRIPT_DIR_SEPARATOR|Missing backslash after SCRIPT_DIR: " script_dir_hits
        if (chained_if_else_hits != "") print "BATCH_CHAINED_IF_ELSE|Chained if ... if ... ( ... ) else ( ... ) skips else when outer if is false: " chained_if_else_hits
      }
    ' "$file" 2>/dev/null || true)
    if [ -n "$cmd_violations" ]; then
      OIFS_V="$IFS"
      IFS='
'
      for v_line in $cmd_violations; do
        log_failure "$file" "${v_line%%|*}" "${v_line#*|}"
      done
      IFS="$OIFS_V"
    fi
  fi

  # 6. Option A Hard Fail Proforma check (Exit code 86)
  case "$file" in
    */mount_target_vfs.cmd|*/umount_target_vfs.cmd|*/runner.cmd|*/provision_disk.cmd|*/format_fs.cmd|*/live_freebsd.cmd|*/live_illumos.cmd|*/live_linux.cmd|*/coinstall_dual_os.cmd|*/install_freebsd.cmd|*/install_illumos.cmd|*/install_linux.cmd|*/multiboot_orchestrator.cmd|*/grub_multiboot.cmd)
      if ! grep -q 'exit /b 86' "$file"; then
        log_failure "$file" "OPTION_A_PROFORMA" "Option A proforma script must exit with status 86."
      fi
      ;;
    */mount_target_vfs.ps1|*/umount_target_vfs.ps1|*/runner.ps1|*/provision_disk.ps1|*/format_fs.ps1)
      if ! grep -q 'exit 86' "$file"; then
        log_failure "$file" "OPTION_A_PROFORMA" "Option A proforma script must exit with status 86."
      fi
      ;;
  esac

  # 8. Recipe Boundary Check for leaf packages (_lib/<category>/<component>/)
  case "$file" in
    _lib/orchestration/*|_lib/storage/*|_lib/_common/*|_lib/cloud/*|_lib/cloud-providers/*|_lib/kernel/*|_lib/bootloaders/*)
      ;;
    _lib/*/*/*.sh)
      boundary_hits=$(grep -nE '^[[:space:]]*(sudo[[:space:]]+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)[[:space:]]' "$file" 2>/dev/null || true)
      if [ -n "$boundary_hits" ]; then
        log_failure "$file" "RECIPE_BOUNDARY" "Tier 1 leaf recipe directly invokes kernel/storage primitive: $boundary_hits"
      fi
      ;;
  esac

  # 8b. Verify _lib/*/*/env.cmd exports across endlocal boundary
  case "$file" in
    _lib/*/env.cmd|_lib/*/*/env.cmd)
      if grep -qi "setlocal" "$file" && ! grep -qi "endlocal" "$file"; then
        log_failure "$file" "ENV_CMD_ENDLOCAL" "env.cmd uses setlocal without endlocal; PATH and variable updates will be lost on return."
      fi
      ;;
  esac

  # 8c. Enforce Zero-Dependency Substrate in core orchestration (_lib/_common/, cli/)
  case "$file" in
    _lib/_common/*.sh|cli/*.sh|cli/*/*.sh|cli/*/*/*.sh)
      interp_hits=$(grep -nE '^[[:space:]]*(python3?[[:space:]]+-c|node[[:space:]]+-e|perl[[:space:]]+-e|ruby[[:space:]]+-e)[[:space:]]' "$file" 2>/dev/null | grep -v 'libscript-allow-interp' || true)
      if [ -n "$interp_hits" ]; then
        log_failure "$file" "ZERO_DEP_SUBSTRATE" "Core orchestration script invokes external interpreter inline: $interp_hits"
      fi
      ;;
  esac

  # 9. Schema 100% Property Description Coverage
  case "$file" in
    *.schema.json)
      if command -v jq >/dev/null 2>&1; then
        missing_desc=$(jq -r '
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
          check_props
        ' "$file" 2>/dev/null || true)
        if [ -n "$missing_desc" ]; then
          log_failure "$file" "SCHEMA_DESCRIPTIONS" "Missing property description(s): $(printf '%s' "$missing_desc" | tr '\n' ' ')"
        fi
      fi
      ;;
  esac
}

# Execute audit based on arguments
if [ "${1:-}" = "--all" ]; then
  OIFS="$IFS"
  IFS='
'
  for candidate in $(git ls-files "*.sh" "*.cmd" "*.bat" "*.ps1" "*.schema.json"); do
    [ -f "$candidate" ] && audit_single_file "$candidate"
  done
  IFS="$OIFS"
  for cat_dir in _lib/*; do
    [ -d "$cat_dir" ] || continue
    [ "$(basename "$cat_dir")" = "_common" ] && continue
    for comp_dir in "$cat_dir"/*; do
      [ -d "$comp_dir" ] || continue
      for req_file in cli.sh cli.cmd setup.sh setup.cmd env.sh env.cmd service.sh service.cmd test.sh test.cmd manifest.json vars.schema.json README.md; do
        if [ ! -f "$comp_dir/$req_file" ]; then
          log_failure "$comp_dir" "VERSION_MANAGER_CONTRACT" "Missing required Version Manager Contract file: $req_file"
        fi
      done
    done
  done
elif [ "${1:-}" = "--staged" ] || [ $# -eq 0 ]; then
  staged_files=$(git diff --no-ext-diff --cached --name-only --diff-filter=ACM || true)
  if [ -z "$staged_files" ]; then
    printf '%s\n' "[AUDIT] No matching files to audit."
    exit 0
  fi
  OIFS="$IFS"
  IFS='
'
  for candidate in $staged_files; do
    [ -f "$candidate" ] && audit_single_file "$candidate"
  done
  IFS="$OIFS"
else
  for candidate in "$@"; do
    [ -f "$candidate" ] && audit_single_file "$candidate"
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[AUDIT] %d standards violation(s) found.\n' "$ERRORS" >&2
  exit 1
fi

printf '%s\n' "[AUDIT] All inspected files adhere to LibScript engineering standards."
exit 0
