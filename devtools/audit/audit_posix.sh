#!/bin/sh
# ## Overview
# Audits shell scripts across the repository for strict POSIX compliance:
# ensures #!/bin/sh shebang, set -feu, absence of bashisms, canonical THIS_FILE=
# resolution dance, and matching Windows batch (.cmd) companion scripts.
# ## Usage
# ./devtools/audit/audit_posix.sh [--all | file1.sh file2.sh ...]
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

printf '%s\n' '=== LibScript POSIX Compliance & Bashism Prohibition Audit ==='

ERRORS=0

# ## audit_batch
# Validates a stream of .sh files (and their .cmd companions) using a single fast awk engine.
audit_batch() {
  _err_file=$(mktemp)
  # shellcheck disable=SC2016
  xargs awk '
    function check_prev() {
      if (prev_f == "" || prev_f ~ /audit_posix\.sh$/) return
      if (first_line != "#!/bin/sh") {
        print "[FAIL] [" prev_f "] Line 1 must be #!/bin/sh (found: " first_line ")"
        errs++
      }
      if (!has_feu) {
        print "[FAIL] [" prev_f "] Missing `set -feu` declaration in header"
        errs++
      }
      if (!has_this) {
        print "[FAIL] [" prev_f "] Missing canonical THIS_FILE= resolution dance in first 30 lines"
        errs++
      }
      if (bad_stack_quote) {
        print "[FAIL] [" prev_f "] Single-quoted literal ${THIS_FILE} in STACK recursion guard"
        errs++
      }
      if (unreachable_stack) {
        print "[FAIL] [" prev_f "] Unreachable STACK pop placed after return/exit"
        errs++
      }
      if (has_dbl_bracket) {
        print "[FAIL] [" prev_f "] Banned bashism: `[[ ... ]]` condition syntax detected"
        errs++
      }
      if (has_func_kw) {
        print "[FAIL] [" prev_f "] Banned bashism: `function foo()` syntax detected"
        errs++
      }
      if (has_source_kw) {
        print "[FAIL] [" prev_f "] Banned bashism: `source` used instead of POSIX `.`"
        errs++
      }
      if (has_echo_e) {
        print "[FAIL] [" prev_f "] Banned bashism: `echo -e` used instead of `printf`"
        errs++
      }
      if (has_sort_v) {
        print "[FAIL] [" prev_f "] Non-POSIX `sort -V` detected; use `libscript_sort_versions`"
        errs++
      }
      if (has_sed_i) {
        print "[FAIL] [" prev_f "] Non-portable `sed -i` detected; use temp file or `libscript_sed_in_place`"
        errs++
      }
      if (has_gnu_bre) {
        print "[FAIL] [" prev_f "] Non-POSIX GNU BRE extension (\\+, \\|, \\?) in grep without -E"
        errs++
      }
      if (dq_hit != "" && prev_f !~ /(audit_posix\.sh|audit_standards\.sh|\.tpl)$/) {
        print "[FAIL] [" prev_f "] Unnecessary double quotes where single quotes suffice: " dq_hit
        errs++
      }
      if (sc2015_hit != "" && prev_f !~ /(audit_posix\.sh|audit_standards\.sh|\.tpl)$/) {
        print "[FAIL] [" prev_f "] SC2015-prone `A && B || true` chain detected (use explicit `if ...; then ... || true; fi`): " sc2015_hit
        errs++
      }
      if (has_unguarded_home) {
        print "[FAIL] [" prev_f "] Unguarded $HOME reference in env.sh; use ${HOME:-/root} for set -u daemon safety"
        errs++
      }
    }
    FNR == 1 {
      check_prev()
      prev_f = FILENAME
      sub(/\r$/, "", $0)
      first_line = $0
      has_feu = 0; has_this = 0; bad_stack_quote = 0; unreachable_stack = 0;
      has_dbl_bracket = 0; has_func_kw = 0; has_source_kw = 0; has_echo_e = 0;
      has_sort_v = 0; has_sed_i = 0; has_gnu_bre = 0; dq_hit = ""; sc2015_hit = ""; has_unguarded_home = 0;
      in_hd = 0; hd_delim = ""; hd_tab = 0; saw_ret_line = -10;
      is_env_sh = (FILENAME ~ /(^|\/)_lib\/[^\/]+\/[^\/]+\/env\.sh$/)
    }
    { sub(/\r$/, "", $0) }
    FNR <= 30 {
      if ($0 !~ /^[[:space:]]*#/ && $0 ~ /set -feu/) has_feu = 1
      if ($0 !~ /^[[:space:]]*#/ && $0 ~ /THIS_FILE=/) has_this = 1
    }
    {
      if (in_hd) {
        if ($0 == hd_delim || (hd_tab && $0 ~ "^[[:space:]]*" hd_delim "$")) {
          in_hd = 0; hd_delim = ""; hd_tab = 0
        }
        next
      }
      if ($0 ~ /<<-?[[:space:]]*["\x27]?[A-Za-z0-9_]+["\x27]?[[:space:]]*(>|2>|$)/ && $0 !~ /^[[:space:]]*#/) {
        in_hd = 1
        hd_tab = ($0 ~ /<<-/)
        hd_delim = $0
        sub(/^.*<<-?[[:space:]]*["\x27]?/, "", hd_delim)
        sub(/["\x27]?[[:space:]]*(>|2>|$).*$/, "", hd_delim)
        next
      }
      if ($0 ~ /\*\x27:"\$\{THIS_FILE\}":\x27\*/) bad_stack_quote = 1
      if ($0 ~ /return 0; else exit 0/) saw_ret_line = FNR
      if (FNR == saw_ret_line + 1 && $0 ~ /^STACK="\$\{STACK%"\$\{THIS_FILE\}":\}"/) unreachable_stack = 1
      if ($0 ~ /(if[[:space:]]+\[\[|[[:space:]]\[\[[[:space:]]|&&[[:space:]]*\[\[|\|\|[[:space:]]*\[\[)/) has_dbl_bracket = 1
      if ($0 ~ /^[[:space:]]*function[[:space:]]+[a-zA-Z0-9_]+([[:space:]]*\([[:space:]]*\))?[[:space:]]*\{?[[:space:]]*$/) has_func_kw = 1
      if ($0 ~ /^[[:space:]]*source[[:space:]]+|[;&|][[:space:]]*source[[:space:]]+/) has_source_kw = 1
      if ($0 ~ /^[[:space:]]*echo[[:space:]]+-e[[:space:]]+|[;&|][[:space:]]*echo[[:space:]]+-e[[:space:]]+/) has_echo_e = 1
      if ($0 !~ /^[[:space:]]*#/) {
        if ($0 ~ /(^|[^A-Za-z0-9_])sort[[:space:]]+-V([^A-Za-z0-9_]|$)/) has_sort_v = 1
        if ($0 ~ /(^|[^A-Za-z0-9_])sed[[:space:]]+-i/) has_sed_i = 1
        if ($0 ~ /(^|[[:space:];|&(])grep[[:space:]]+/ && $0 !~ /grep[[:space:]]+-[a-zA-Z]*[EF]/ && $0 ~ /\\[+|?]/) has_gnu_bre = 1
        if (dq_hit == "") {
          if ($0 ~ /^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*="[A-Za-z0-9_.\/:@+-]+"[[:space:]]*$/ ||
              $0 ~ /^[[:space:]]*(log_(info|warn|error)|printf[[:space:]]+\x27%s\\n\x27|echo)[[:space:]]+"[^$`\x5c\x27"]+"([[:space:]]*>&2)?[[:space:]]*$/ ||
              $0 ~ /^[[:space:]]*libscript_depends([[:space:]]+"[A-Za-z0-9_.-]+")+([[:space:]]*\|\|[[:space:]]*true)?[[:space:]]*$/) {
            dq_hit = FNR ":" $0
          }
        }
        if (sc2015_hit == "") {
          if ($0 ~ /^[ \t]*(\x5b[^\x5d]+\x5d([ \t]*&&[ \t]*\x5b[^\x5d]+\x5d)*|command[ \t]+-v[ \t]+[^|;]+)[ \t]*&&[ \t]*[^|;&\x5b{][^|;&]*(\|[ \t]*[^|;&]+)*\|\|[ \t]*(true|:)([ \t;]|$)/) {
            sc2015_hit = FNR ":" $0
          }
        }
        if (is_env_sh && $0 ~ /\$HOME([^A-Za-z0-9_]|$)|(\$\{HOME\})/) has_unguarded_home = 1
      }
    }
    END {
      check_prev()
    }
  ' >> "$_err_file"

  if [ -s "$_err_file" ]; then
    cat "$_err_file" >&2
    _cnt=$(wc -l < "$_err_file" | tr -d ' ')
    ERRORS=$((ERRORS + _cnt))
  fi
  rm -f "$_err_file"
}

# ## audit_companions
# Verifies bidirectional .sh and .cmd/.bat pairing and Windows batch header invariants.
audit_companions() {
  _comp_err=$(mktemp)
  awk '
    {
      sub(/\r$/, "", $0)
      files[$0] = 1
    }
    END {
      for (f in files) {
        if (f ~ /\.sh$/ && f !~ /(^|\/)audit_posix\.sh$/) {
          base = substr(f, 1, length(f) - 3)
          cmd = base ".cmd"
          bat = base ".bat"
          if (!(cmd in files) && !(bat in files)) {
            print "[FAIL] [" f "] Missing paired Windows batch companion: " cmd
          }
        }
        if (f ~ /\.(cmd|bat)$/) {
          base = substr(f, 1, length(f) - 4)
          sh = base ".sh"
          if (!(sh in files)) {
            print "[FAIL] [" f "] Missing paired POSIX shell companion: " sh
          }
        }
      }
    }
  ' >> "$_comp_err"

  if [ -s "$_comp_err" ]; then
    cat "$_comp_err" >&2
    _cnt=$(wc -l < "$_comp_err" | tr -d ' ')
    ERRORS=$((ERRORS + _cnt))
  fi
  rm -f "$_comp_err"

  _cmd_hdr_err=$(mktemp)
  (cd "$LIBSCRIPT_ROOT_DIR" && git ls-files --cached --others --exclude-standard "*.cmd" "*.bat") | (
    # shellcheck disable=SC2016
    cd "$LIBSCRIPT_ROOT_DIR" && xargs awk '
      function check_cmd() {
        if (prev_c == "") return
        if (!has_del) print "[FAIL] [" prev_c "] Windows companion missing EnableDelayedExpansion"
        if (!has_this) print "[FAIL] [" prev_c "] Windows companion missing THIS_FILE= definition"
        if (!has_stack_guard) print "[FAIL] [" prev_c "] Windows companion missing quoted case-insensitive STACK guard (echo \"!STACK!\" | findstr /I)"
      }
      FNR == 1 {
        check_cmd()
        prev_c = FILENAME
        has_del = 0; has_this = 0; has_stack_guard = 0
      }
      FNR <= 25 {
        sub(/\r$/, "", $0)
        line_l = tolower($0)
        if (line_l !~ /^[[:space:]]*(::|rem([[:space:]]|$))/) {
          if (line_l ~ /^[[:space:]]*setlocal[[:space:]]+enabledelayedexpansion/) has_del = 1
          if (line_l ~ /this_file=/) has_this = 1
          if (line_l ~ /echo "!stack!" \| findstr \/i \/c:":/) has_stack_guard = 1
        }
      }
      END { check_cmd() }
    '
  ) >> "$_cmd_hdr_err"

  if [ -s "$_cmd_hdr_err" ]; then
    cat "$_cmd_hdr_err" >&2
    _cnt=$(wc -l < "$_cmd_hdr_err" | tr -d ' ')
    ERRORS=$((ERRORS + _cnt))
  fi
  rm -f "$_cmd_hdr_err"
}

if [ "${1:-}" = "--staged" ]; then
  _staged_list=$(mktemp)
  (cd "$LIBSCRIPT_ROOT_DIR" && git diff --no-ext-diff --cached --name-only --diff-filter=ACM -- "*.sh" | sed "s|^|${LIBSCRIPT_ROOT_DIR}/|") > "$_staged_list"
  if [ -s "$_staged_list" ]; then
    audit_batch < "$_staged_list"
  fi
  rm -f "$_staged_list"
elif [ $# -gt 0 ] && [ "${1:-}" != "--all" ]; then
  _target_list=$(mktemp)
  for _t in "$@"; do
    if [ -f "$_t" ]; then
      printf '%s\n' "$_t" >> "$_target_list"
      _cmd="${_t%.sh}.cmd"
      _bat="${_t%.sh}.bat"
      if [ ! -f "$_cmd" ] && [ ! -f "$_bat" ]; then
        printf '[FAIL] [%s] Missing paired Windows batch companion: %s\n' "$_t" "$_cmd" >&2
        ERRORS=$((ERRORS + 1))
      elif [ -f "$_cmd" ]; then
        if ! head -n 25 "$_cmd" | grep -qi 'EnableDelayedExpansion'; then
          printf '[FAIL] [%s] Windows companion missing EnableDelayedExpansion\n' "$_cmd" >&2
          ERRORS=$((ERRORS + 1))
        fi
        if ! head -n 25 "$_cmd" | grep -qi 'THIS_FILE='; then
          printf '[FAIL] [%s] Windows companion missing THIS_FILE= definition\n' "$_cmd" >&2
          ERRORS=$((ERRORS + 1))
        fi
      fi
    fi
  done
  if [ -s "$_target_list" ]; then
    audit_batch < "$_target_list"
  fi
  rm -f "$_target_list"
else
  _all_sh=$(mktemp)
  _all_scripts=$(mktemp)
  (cd "$LIBSCRIPT_ROOT_DIR" && git ls-files --cached --others --exclude-standard "*.sh" | sed "s|^|${LIBSCRIPT_ROOT_DIR}/|") > "$_all_sh"
  (cd "$LIBSCRIPT_ROOT_DIR" && git ls-files --cached --others --exclude-standard "*.sh" "*.cmd" "*.bat") > "$_all_scripts"
  audit_batch < "$_all_sh"
  audit_companions < "$_all_scripts"
  rm -f "$_all_sh" "$_all_scripts"
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[ERROR] Audit failed with %d standards violations!\n' "$ERRORS" >&2
  exit 1
fi

printf '%s\n' '[PASS] All audited scripts strictly adhere to POSIX /bin/sh and companion requirements.'
exit 0
