#!/bin/sh
# ## Overview
# Audits shell scripts across the repository for strict POSIX compliance:
# ensures #!/bin/sh shebang, set -feu, absence of bashisms, canonical THIS_FILE=
# resolution dance, and matching Windows batch (.cmd) companion scripts.
#
# ## Usage
# ./devtools/audit/audit_posix.sh [file1.sh file2.sh ...]

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

printf '=== LibScript POSIX Compliance & Bashism Prohibition Audit ===\n'

ERRORS=0

# ## audit_file
# Validates individual file against strict POSIX /bin/sh invariants and Windows batch pairing.
audit_file() {
  file="$1"
  [ -f "$file" ] || return 0
  case "$file" in
    *audit_posix.sh) return 0 ;;
  esac

  # 1. Shebang check
  first_line=$(head -n 1 "$file")
  if [ "$first_line" != "#!/bin/sh" ]; then
    printf '[FAIL] [%s] Line 1 must be #!/bin/sh (found: %s)\n' "$file" "$first_line" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 2. set -feu check
  if ! head -n 35 "$file" | grep -q "set -feu"; then
    printf '[FAIL] [%s] Missing `set -feu` declaration in header\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 3. Canonical THIS_FILE= dance check
  if ! head -n 65 "$file" | grep -q 'THIS_FILE='; then
    printf '[FAIL] [%s] Missing canonical THIS_FILE= resolution dance in first 65 lines\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi
  if grep -q "\*':\"\${THIS_FILE}\"':\*" "$file" 2>/dev/null; then
    printf '[FAIL] [%s] Single-quoted literal ${THIS_FILE} in STACK recursion guard\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi
  if grep -B 1 '^STACK="\${STACK%"\${THIS_FILE}":}"' "$file" 2>/dev/null | grep -q 'return 0; else exit 0'; then
    printf '[FAIL] [%s] Unreachable STACK pop placed after return/exit\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4. Banned Bashisms checks
  if grep -E '(if[[:space:]]+\[\[|[[:space:]]\[\[[[:space:]]|&&[[:space:]]*\[\[|\|\|[[:space:]]*\[\[)' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `[[ ... ]]` condition syntax detected\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '^[[:space:]]*function[[:space:]]+[a-zA-Z0-9_]+([[:space:]]*\([[:space:]]*\))?[[:space:]]*\{?[[:space:]]*$' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `function foo()` syntax detected\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '^[[:space:]]*source[[:space:]]+|[;&|][[:space:]]*source[[:space:]]+' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `source` used instead of POSIX `.`\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -nE '^[[:space:]]*echo[[:space:]]+-e[[:space:]]+|[;&|][[:space:]]*echo[[:space:]]+-e[[:space:]]+' "$file" >/dev/null 2>&1; then
    printf '[FAIL] [%s] Banned bashism: `echo -e` used instead of `printf`\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -v '^[[:space:]]*#' "$file" | grep -E '\bsort[[:space:]]+-V\b' >/dev/null 2>&1; then
    printf '[FAIL] [%s] Non-POSIX `sort -V` detected; use `libscript_sort_versions`\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  if grep -v '^[[:space:]]*#' "$file" | grep -E '\bsed[[:space:]]+-i' >/dev/null 2>&1; then
    printf '[FAIL] [%s] Non-portable `sed -i` detected; use temp file or `libscript_sed_in_place`\n' "$file" >&2
    ERRORS=$((ERRORS + 1))
  fi

  # 4b. Unnecessary double quotes check (outside comments and heredocs)
  _dq_hits=$(awk '
    {
      sub(/\r$/, "", $0)
      if (in_hd) {
        if ($0 == hd_delim || (hd_tab && $0 ~ "^[[:space:]]*" hd_delim "$")) {
          in_hd = 0
          hd_delim = ""
          hd_tab = 0
        }
        next
      }
      if ($0 ~ /<<-?[[:space:]]*["'\'']?[A-Za-z0-9_]+["'\'']?[[:space:]]*(>|2>|$)/ && $0 !~ /^[[:space:]]*#/) {
        in_hd = 1
        hd_tab = ($0 ~ /<<-/)
        hd_delim = $0
        sub(/^.*<<-?[[:space:]]*["'\'']?/, "", hd_delim)
        sub(/["'\'']?[[:space:]]*(>|2>|$).*$/, "", hd_delim)
        next
      }
      if ($0 ~ /^[[:space:]]*#/) next
      if ($0 ~ /^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*="[A-Za-z0-9_.\/:@+-]+"[[:space:]]*$/ ||
          $0 ~ /^[[:space:]]*(log_(info|warn|error)|printf[[:space:]]+\x27%s\\n\x27|echo)[[:space:]]+"[^$`\x5c\x27"]+"([[:space:]]*>&2)?[[:space:]]*$/ ||
          $0 ~ /^[[:space:]]*libscript_depends([[:space:]]+"[A-Za-z0-9_.-]+")+([[:space:]]*\|\|[[:space:]]*true)?[[:space:]]*$/) {
        print NR ":" $0
      }
    }
  ' "$file" 2>/dev/null || true)
  if [ -n "$_dq_hits" ]; then
    printf '[FAIL] [%s] Unnecessary double quotes where single quotes suffice: %s\n' "$file" "$(printf '%s' "$_dq_hits" | head -n 1)" >&2
    ERRORS=$((ERRORS + 1))
  fi

  case "$file" in
    */_lib/*/*/env.sh)
      if grep -v '^[[:space:]]*#' "$file" | grep -E '\$HOME([^A-Za-z0-9_]|$)|(\$\{HOME\})' >/dev/null 2>&1; then
        printf '[FAIL] [%s] Unguarded $HOME reference in env.sh; use ${HOME:-/root} for set -u daemon safety\n' "$file" >&2
        ERRORS=$((ERRORS + 1))
      fi
      ;;
  esac

  # 5. Matching .cmd companion check
  cmd_companion="${file%.sh}.cmd"
  if [ ! -f "$cmd_companion" ]; then
    printf '[FAIL] [%s] Missing paired Windows batch companion: %s\n' "$file" "$cmd_companion" >&2
    ERRORS=$((ERRORS + 1))
  else
    if ! head -n 25 "$cmd_companion" | grep -qi "EnableDelayedExpansion"; then
      printf '[FAIL] [%s] Windows companion missing EnableDelayedExpansion\n' "$cmd_companion" >&2
      ERRORS=$((ERRORS + 1))
    fi
    if ! head -n 25 "$cmd_companion" | grep -qi "THIS_FILE="; then
      printf '[FAIL] [%s] Windows companion missing THIS_FILE= definition\n' "$cmd_companion" >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

if [ $# -gt 0 ]; then
  if [ "${1:-}" = "--all" ]; then
    shift
    for script in $(cd "$LIBSCRIPT_ROOT_DIR" && git ls-files "*.sh"); do
      audit_file "${LIBSCRIPT_ROOT_DIR}/${script}"
    done
    for cmd_script in $(cd "$LIBSCRIPT_ROOT_DIR" && git ls-files "*.cmd" "*.bat"); do
      sh_companion="${LIBSCRIPT_ROOT_DIR}/${cmd_script%.*}.sh"
      if [ ! -f "$sh_companion" ]; then
        printf '[FAIL] [%s] Missing paired POSIX shell companion: %s\n' "$cmd_script" "$sh_companion" >&2
        ERRORS=$((ERRORS + 1))
      fi
    done
  else
    for target in "$@"; do
      audit_file "$target"
    done
  fi
else
  for script in $(cd "$LIBSCRIPT_ROOT_DIR" && git ls-files "*.sh"); do
    audit_file "${LIBSCRIPT_ROOT_DIR}/${script}"
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[ERROR] Audit failed with %d standards violations!\n' "$ERRORS" >&2
  exit 1
fi

printf '[PASS] All audited scripts strictly adhere to POSIX /bin/sh and companion requirements.\n'
exit 0
