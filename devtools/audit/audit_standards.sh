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

set -eu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage and help information for the audit tool.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [--all | --staged | <file>...]"
  printf '%s
' "Audits files for adherence to LibScript engineering standards."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --all               Audit all tracked script files in repository."
  printf '%s
' "  --staged            Audit git-staged files (default if no files given)."
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

cd "$REPO_ROOT"

ERRORS=0

# ## log_failure
# Records and outputs an audit violation message.
log_failure() {
  target_file="$1"
  rule_name="$2"
  details="$3"
  printf '[STANDARDS VIOLATION] [%s] %s: %s
' "$rule_name" "$target_file" "$details" >&2
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

  # 1. POSIX /bin/sh and THIS_FILE dance (for .sh files)
  if [ "$ext" = "sh" ]; then
    first_line=$(head -n 1 "$file" 2>/dev/null || true)
    case "$first_line" in
      *bash*|*zsh*|*ksh*)
        log_failure "$file" "POSIX_SHEBANG" "Non-POSIX shebang found: '$first_line'. LibScript requires '#!/bin/sh'."
        ;;
      "#!/bin/sh"*)
        ;;
      *)
        case "$file" in
          *.tpl|*.template|*docker*|*test*|*docs-web-template*) ;;
          *)
            log_failure "$file" "POSIX_SHEBANG" "Missing '#!/bin/sh' shebang on line 1."
            ;;
        esac
        ;;
    esac

    # Validate no duplicate shebangs outside of heredocs
    multi_shebangs=$(awk '
      BEGIN { in_heredoc = 0; delim = ""; count = 0; lines = ""; }
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
          count++
          lines = (lines ? lines ", " : "") NR
        }
      }
      END {
        if (count > 1) {
          print lines
        }
      }
    ' "$file" 2>/dev/null || true)
    if [ -n "$multi_shebangs" ]; then
      log_failure "$file" "DUPLICATE_SHEBANG" "Multiple shebangs found outside of heredocs at lines: $multi_shebangs."
    fi

    # Validate THIS_FILE preamble dance in first 65 lines
    head_block=$(head -n 65 "$file" 2>/dev/null || true)
    case "$file" in
      *Dockerfile*|*.tpl|*dockerfiles-ssh*|*docker/*)
        ;;
      *)
        if ! printf '%s\n' "$head_block" | grep -q 'THIS_FILE='; then
          log_failure "$file" "THIS_FILE_DANCE" "Missing canonical 'THIS_FILE=' resolution in first 65 lines."
        fi
        if ! printf '%s\n' "$head_block" | grep -q 'STACK'; then
          log_failure "$file" "RECURSION_GUARD" "Missing 'STACK' recursion guard in first 65 lines."
        fi
        ;;
    esac

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

  # Validate Windows batch headers
  if [ "$ext" = "cmd" ] || [ "$ext" = "bat" ]; then
    cmd_head=$(head -n 25 "$file" 2>/dev/null || true)
    if ! printf '%s\n' "$cmd_head" | grep -qi 'THIS_FILE=%~f0'; then
      log_failure "$file" "BATCH_THIS_FILE" "Missing 'set \"THIS_FILE=%~f0\"' in first 25 lines."
    fi
  fi

  # 3. Idempotency checks
  if [ "$ext" = "sh" ]; then
    # Catch unguarded mkdir without -p (excluding atomic lock acquisition patterns)
    unguarded_mkdir=$(grep -nE '^[[:space:]]*mkdir[[:space:]]+[^-]' "$file" 2>/dev/null | grep -vEi 'lock|while|if[[:space:]]+!' || true)
    if [ -n "$unguarded_mkdir" ]; then
      log_failure "$file" "IDEMPOTENCY" "Unguarded 'mkdir' found without '-p': $unguarded_mkdir. Use 'mkdir -p' for idempotency."
    fi
    # Catch unguarded ln -s without -f
    unguarded_ln=$(grep -nE '^[[:space:]]*ln[[:space:]]+-s[[:space:]]+[^-]' "$file" 2>/dev/null || true)
    if [ -n "$unguarded_ln" ]; then
      log_failure "$file" "IDEMPOTENCY" "Unguarded 'ln -s' found without '-f': $unguarded_ln. Use 'ln -sf' for idempotency."
    fi
  elif [ "$ext" = "cmd" ] || [ "$ext" = "bat" ]; then
    # Catch unguarded mkdir in batch without if not exist
    unguarded_batch_mkdir=$(grep -nEi '^[[:space:]]*(mkdir|md)[[:space:]]+' "$file" 2>/dev/null | grep -vEi 'if[[:space:]]+not[[:space:]]+exist' || true)
    if [ -n "$unguarded_batch_mkdir" ]; then
      log_failure "$file" "IDEMPOTENCY" "Unguarded 'mkdir' in batch script: $unguarded_batch_mkdir. Wrap with 'if not exist <dir> mkdir <dir>'."
    fi
  fi

  # 4. Ban eval check
  if [ "$ext" = "sh" ] || [ "$ext" = "ps1" ]; then
    if [ "$ext" = "sh" ]; then
      eval_hits=$(grep -nE '^[[:space:]]*eval([[:space:]]|$)|;[[:space:]]*eval([[:space:]]|$)' "$file" | grep -v 'libscript-allow-eval' || true)
    else
      eval_hits=$(grep -nEi '^[[:space:]]*(Invoke-Expression|iex)\b|;[[:space:]]*(Invoke-Expression|iex)\b' "$file" | grep -v 'libscript-allow-eval' || true)
    fi
    if [ -n "$eval_hits" ]; then
      log_failure "$file" "BAN_EVAL" "Disallowed use of eval/Invoke-Expression found: $eval_hits"
    fi
  fi

  # 5. 100% Doc coverage (## Overview and ## Usage)
  case "$ext" in
    sh|cmd|bat|ps1)
      doc_header=$(head -n 30 "$file" 2>/dev/null || true)
      if ! printf '%s\n' "$doc_header" | grep -q '## Overview'; then
        log_failure "$file" "DOC_OVERVIEW" "Missing doc block '## Overview' in first 30 lines."
      fi
      if ! printf '%s\n' "$doc_header" | grep -q '## Usage'; then
        log_failure "$file" "DOC_USAGE" "Missing doc block '## Usage' in first 30 lines."
      fi
      ;;
  esac

  # 6. Option A Hard Fail Proforma check (Exit code 86)
  case "$file" in
    *mount_target_vfs.cmd|*umount_target_vfs.cmd|*runner.cmd|*provision_disk.cmd|*format_fs.cmd)
      if ! grep -q 'exit /b 86' "$file"; then
        log_failure "$file" "OPTION_A_PROFORMA" "Option A proforma script must exit with status 86."
      fi
      ;;
    *mount_target_vfs.ps1|*umount_target_vfs.ps1|*runner.ps1|*provision_disk.ps1|*format_fs.ps1)
      if ! grep -q 'exit 86' "$file"; then
        log_failure "$file" "OPTION_A_PROFORMA" "Option A proforma script must exit with status 86."
      fi
      ;;
  esac

  # 7. Remote Safety Mandate (NEVER execute git push)
  case "$ext" in
    sh|cmd|bat|ps1)
      git_push_hits=$(grep -nE '^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push\b' "$file" 2>/dev/null || true)
      if [ -n "$git_push_hits" ]; then
        log_failure "$file" "REMOTE_SAFETY" "Strict safety violation: found 'git push' invocation: $git_push_hits"
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

printf '%s
' "[AUDIT] All inspected files adhere to LibScript engineering standards."
exit 0
