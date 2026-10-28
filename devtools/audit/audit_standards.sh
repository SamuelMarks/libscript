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
  printf '%s\n' 'Audits files for adherence to LibScript engineering standards.'
  printf '
'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --all               Audit all tracked script files in repository.'
  printf '%s\n' '  --staged            Audit git-staged files (default if no files given).'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

ORIG_PWD=$(pwd)
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
        has_overview = 0; has_usage = 0; has_set_feu = 0;
        mkdir_hits = ""; ln_hits = ""; eval_hits = ""; git_push_hits = "";
      }
      NR == 1 {
        first_line = $0
      }
      NR <= 30 {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      NR <= 38 {
        if ($0 ~ /set -feu/) has_set_feu = 1
        if ($0 ~ /THIS_FILE=/) has_this_file = 1
        if ($0 ~ /STACK/) has_stack = 1
        if ($0 ~ /LIBSCRIPT_ROOT_DIR/) has_root_dir = 1
        if ($0 ~ /# shellcheck disable=SC2296/) has_zsh_sc = 1
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
        if ($0 ~ /^[[:space:]]*eval([[:space:]]|$)/ || $0 ~ /;[[:space:]]*eval([[:space:]]|$)/) {
          eval_hits = (eval_hits ? eval_hits "; " : "") NR ":" $0
        }
        if ($0 ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
          git_push_hits = (git_push_hits ? git_push_hits "; " : "") NR ":" $0
        }
        if ($0 !~ /^[[:space:]]*#/ && $0 !~ /libscript-allow-raw-pkg/) {
          if ($0 ~ /(^|[[:space:];|&])(priv[[:space:]]+|sudo[[:space:]]+)?(apt-get[[:space:]]+(install|remove|purge|update)|apt[[:space:]]+(install|remove|purge)|apk[[:space:]]+(add|del|update)|dnf[[:space:]]+(install|remove|groupinstall)|yum[[:space:]]+(install|remove|groupinstall)|pacman[[:space:]]+(-S|-R|-Rns|-Syu)|zypper[[:space:]]+(install|in|remove|rm)|brew[[:space:]]+(install|uninstall|tap|services)|port[[:space:]]+(install|uninstall)|pkg[[:space:]]+(install|delete|add)|xbps-install|xbps-remove|emerge[[:space:]]|swupd[[:space:]]+bundle-add|winget[[:space:]]+(install|uninstall|upgrade)|choco[[:space:]]+(install|uninstall|upgrade)|scoop[[:space:]]+(install|uninstall|update)|vcpkg[[:space:]]+(install|remove)|conan[[:space:]]+install|nix[[:space:]]+profile[[:space:]]+install|nix-env[[:space:]]+-i|guix[[:space:]]+(install|package)|spack[[:space:]]+(install|uninstall)|npm[[:space:]]+install[[:space:]]+-g|composer[[:space:]]+global[[:space:]]+require)([[:space:]]|$)/) {
            if ($0 !~ /--root/) {
              adhoc_pkg_hits = (adhoc_pkg_hits ? adhoc_pkg_hits "; " : "") NR ":" $0
            }
          }
        }
        if ($0 !~ /^[[:space:]]*#/ && $0 !~ /libscript-allow-raw-(fetch|curl)/) {
          if ($0 ~ /(^|[[:space:];|&(])(curl[[:space:]]+-[a-zA-Z0-9#-]*[sSfLOo]|wget[[:space:]]+-[a-zA-Z0-9-]*[qO]|aria2c[[:space:]]+-[dox])([[:space:]]|$)/ && $0 !~ /(127\.0\.0\.1|localhost|--unix-socket|--cacert|--connect-timeout|-w[[:space:]]+"%\{http_code\}")/) {
            raw_fetch_hits = (raw_fetch_hits ? raw_fetch_hits "; " : "") NR ":" $0
          }
        }
        if ($0 !~ /^[[:space:]]*#/) {
          if ($0 ~ /SCRIPT_NAME=/) {
            last_script_name_nr = NR
          }
          if ($0 ~ /^[[:space:]]*\.[[:space:]]+["\x27]?(\$[{]?SCRIPT_DIR[}]?|\$[{]?LIBSCRIPT_ROOT_DIR[}]?|\$[{]?REPO_ROOT[}]?)\/[^[:space:]"\x27;]+\.sh["\x27]?([[:space:]]|$)/) {
            if (NR - last_script_name_nr > 4 && $0 !~ /SCRIPT_NAME/) {
              unguarded_src_hits = (unguarded_src_hits ? unguarded_src_hits "; " : "") NR ":" $0
            }
          }
          if ($0 ~ /^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*="[A-Za-z0-9_.\/:@+-]+"[[:space:]]*$/ ||
              $0 ~ /^[[:space:]]*(log_(info|warn|error)|printf[[:space:]]+'\''%s\\n'\''|echo)[[:space:]]+"[^$`\\'\''"]+"([[:space:]]*>&2)?[[:space:]]*$/ ||
              $0 ~ /^[[:space:]]*libscript_depends([[:space:]]+"[A-Za-z0-9_.-]+")+([[:space:]]*\|\|[[:space:]]*true)?[[:space:]]*$/) {
            unnecessary_dq_hits = (unnecessary_dq_hits ? unnecessary_dq_hits "; " : "") NR ":" $0
          }
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
        if (!has_set_feu) print "SET_FEU_SAFETY|Missing set -feu in first 38 lines."
        if (!has_this_file) print "THIS_FILE_DANCE|Missing canonical THIS_FILE= resolution in first 30 lines."
        if (!has_stack) print "RECURSION_GUARD|Missing STACK recursion guard in first 35 lines."
        if (!has_root_dir) print "ROOT_DIR_RESOLUTION|Missing LIBSCRIPT_ROOT_DIR resolution in header."
        if (!has_zsh_sc) print "ZSH_SHELLCHECK_TAG|Missing # shellcheck disable=SC2296 in ZSH_VERSION header block."
        if (!has_overview) print "DOC_OVERVIEW|Missing doc block ## Overview in first 30 lines."
        if (!has_usage) print "DOC_USAGE|Missing doc block ## Usage in first 30 lines."
        if (mkdir_hits != "") print "IDEMPOTENCY|Unguarded mkdir found without -p: " mkdir_hits
        if (ln_hits != "") print "IDEMPOTENCY|Unguarded ln -s found without -f: " ln_hits
        if (eval_hits != "") print "BAN_EVAL|Disallowed use of eval found: " eval_hits
        if (git_push_hits != "") print "REMOTE_SAFETY|Strict safety violation: found git push invocation: " git_push_hits
        if (adhoc_pkg_hits != "") print "RAW_PACKAGE_MANAGER|Raw package manager usage found (delegate to pkg_mgr.sh / libscript_depends): " adhoc_pkg_hits
        if (raw_fetch_hits != "") print "RAW_NETWORK_FETCH|Raw curl/wget/aria2c network call found (delegate to libscript_download or libscript_fetch_stdout): " raw_fetch_hits
        if (unguarded_src_hits != "") print "UNGUARDED_SOURCE_SH|Sourcing LibScript .sh file without setting SCRIPT_NAME first: " unguarded_src_hits
        if (unnecessary_dq_hits != "") print "UNNECESSARY_DOUBLE_QUOTES|Double quotes used where single quotes suffice: " unnecessary_dq_hits
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
          THIS_FILE_DANCE|RECURSION_GUARD|ROOT_DIR_RESOLUTION|ZSH_SHELLCHECK_TAG)
            case "$file" in
              *Dockerfile*|*.tpl|*dockerfiles-ssh*|*docker/*) ;;
              *) log_failure "$file" "$v_rule" "$v_msg" ;;
            esac
            ;;
          RAW_PACKAGE_MANAGER)
            case "$file" in
              *_lib/_common/pkg_mgr.sh|*_lib/_common/service.sh|*_lib/package-managers/*|*_lib/orchestration/distro/*|*tests/*|*devtools/ci/*|*devtools/audit/*|*docker*) ;;
              *) log_failure "$file" "$v_rule" "$v_msg" ;;
            esac
            ;;
          RAW_NETWORK_FETCH)
            case "$file" in
              *_lib/_common/pkg_mgr.sh|*_lib/init-systems/daemonize.sh|*_lib/utilities/curl/test.sh|*_lib/utilities/wget/test.sh|*_lib/utilities/aria2/test.sh|*_lib/web-apps/*/test_harness.sh|*_lib/web-apps/*/health*.sh|*_lib/web-apps/*/service.sh|*tests/*|*devtools/ci/*|*devtools/capture_*|*devtools/render_*|*devtools/verify_*|*devtools/wait_*|*devtools/trigger_*|*docker*) ;;
              *) log_failure "$file" "$v_rule" "$v_msg" ;;
            esac
            ;;
          UNNECESSARY_DOUBLE_QUOTES)
            case "$file" in
              *audit_posix.sh|*audit_standards.sh|*.tpl) ;;
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
      BEGIN { has_overview = 0; has_usage = 0; eval_hits = ""; git_push_hits = ""; raw_fetch_hits = ""; raw_pkg_hits = ""; allow_fetch_next = 0 }
      { sub(/\r$/, "", $0) }
      NR <= 30 {
        if ($0 ~ /## Overview/) has_overview = 1
        if ($0 ~ /## Usage/) has_usage = 1
      }
      {
        if ($0 ~ /libscript-allow-raw-fetch/) { allow_fetch_next = 1; next }
        if (tolower($0) ~ /^[[:space:]]*(invoke-expression|iex)([[:space:]]|$)/) {
          eval_hits = (eval_hits ? eval_hits "; " : "") NR ":" $0
        }
        if (tolower($0) ~ /^[[:space:]]*(call[[:space:]]+)?git[[:space:]]+push([[:space:]]|$)/) {
          git_push_hits = (git_push_hits ? git_push_hits "; " : "") NR ":" $0
        }
        if ($0 !~ /^[[:space:]]*#/ && !allow_fetch_next) {
          if (tolower($0) ~ /(^|[[:space:];|&(])(invoke-webrequest|invoke-restmethod|iwr|irm|start-bitstransfer|net\.webclient)([[:space:]]|$)/ && tolower($0) !~ /(127\.0\.0\.1|localhost)/) {
            raw_fetch_hits = (raw_fetch_hits ? raw_fetch_hits "; " : "") NR ":" $0
          }
        }
        if ($0 !~ /^[[:space:]]*#/ && $0 !~ /libscript-allow-raw-pkg/) {
          if (tolower($0) ~ /(^|[[:space:];|&&])(winget[[:space:]]+(install|uninstall|upgrade)|choco[[:space:]]+(install|uninstall|upgrade)|scoop[[:space:]]+(install|uninstall|update))([[:space:]]|$)/) {
            raw_pkg_hits = (raw_pkg_hits ? raw_pkg_hits "; " : "") NR ":" $0
          }
        }
        allow_fetch_next = 0
      }
      END {
        if (!has_overview) print "DOC_OVERVIEW|Missing doc block ## Overview in first 30 lines."
        if (!has_usage) print "DOC_USAGE|Missing doc block ## Usage in first 30 lines."
        if (eval_hits != "") print "BAN_EVAL|Disallowed use of Invoke-Expression found: " eval_hits
        if (git_push_hits != "") print "REMOTE_SAFETY|Strict safety violation: found git push invocation: " git_push_hits
        if (raw_fetch_hits != "") print "RAW_NETWORK_FETCH|Raw Invoke-WebRequest/Invoke-RestMethod found (delegate to pkg_mgr.ps1): " raw_fetch_hits
        if (raw_pkg_hits != "") print "RAW_PACKAGE_MANAGER|Raw winget/choco/scoop invocation found (delegate to pkg_mgr.ps1): " raw_pkg_hits
      }
    ' "$file" 2>/dev/null || true)
    if [ -n "$ps1_violations" ]; then
      OIFS_V="$IFS"
      IFS='
'
      for v_line in $ps1_violations; do
        v_rule="${v_line%%|*}"
        v_msg="${v_line#*|}"
        case "$v_rule" in
          RAW_NETWORK_FETCH)
            case "$file" in
              *_lib/_common/pkg_mgr.ps1|*devtools/*|*tests/*) ;;
              *) log_failure "$file" "$v_rule" "$v_msg" ;;
            esac
            ;;
          RAW_PACKAGE_MANAGER)
            case "$file" in
              *_lib/_common/pkg_mgr.ps1|*_lib/package-managers/*|*devtools/*|*tests/*) ;;
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
  fi

  # Validate Windows batch headers, idempotency, docstrings, and safety in single awk pass
  if [ "$ext" = "cmd" ] || [ "$ext" = "bat" ]; then
    sh_equiv="${file%.*}.sh"
    if [ ! -f "$sh_equiv" ]; then
      log_failure "$file" "POSIX_PARITY" "Missing POSIX shell equivalent file ('$sh_equiv') for Windows batch script."
    fi
    cmd_violations=$(awk '
      BEGIN {
        has_echo_off = 0; has_delayed = 0; has_this_file = 0;
        has_overview = 0; has_usage = 0; has_dup_stack = 0;
        mkdir_hits = ""; git_push_hits = ""; script_dir_hits = ""; chained_if_else_hits = "";
        bad_script_dir_strip = ""; tab_path_hits = ""; endlocal_delayed_hits = "";
        raw_fetch_hits = ""; raw_pkg_hits = "";
        in_endlocal = 0;
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
        if (tolower($0) ~ /^[[:space:]]*exit[[:space:]]+[0-9]+[[:space:]]*$/) {
          bare_exit_hits = (bare_exit_hits ? bare_exit_hits "; " : "") NR ":" $0
        }
        if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]]|echo[[:space:]])/ && $0 !~ /libscript-allow-raw-fetch/) {
          if (tolower($0) ~ /(invoke-webrequest|invoke-restmethod|[[:space:]"]iwr[[:space:]]|[[:space:]"]irm[[:space:]]|certutil[[:space:]]+-urlcache|curl[[:space:]]+-[a-z0-9]*[sflo])/ && tolower($0) !~ /(127\.0\.0\.1|localhost|--cacert)/) {
            raw_fetch_hits = (raw_fetch_hits ? raw_fetch_hits "; " : "") NR ":" $0
          }
        }
        if (tolower($0) !~ /^[[:space:]]*(::|rem[[:space:]])/ && $0 !~ /libscript-allow-raw-pkg/) {
          if (tolower($0) ~ /(^|[[:space:]&(])(call[[:space:]]+)?(winget[[:space:]]+(install|uninstall|upgrade)|choco[[:space:]]+(install|uninstall|upgrade)|scoop[[:space:]]+(install|uninstall|update))([[:space:]]|$)/) {
            raw_pkg_hits = (raw_pkg_hits ? raw_pkg_hits "; " : "") NR ":" $0
          }
        }
        if ($0 ~ /SCRIPT_DIR[%!][^\\\/"[:space:])]/) {
          script_dir_hits = (script_dir_hits ? script_dir_hits "; " : "") NR ":" $0
        }
        if ($0 ~ /SCRIPT_DIR:~-1(%|!)""==""/ || $0 ~ /SCRIPT_DIR:~-1%"==""/ || index($0, "SCRIPT_DIR:~-1%\"==\"\\\\\"") > 0) {
          bad_script_dir_strip = (bad_script_dir_strip ? bad_script_dir_strip "; " : "") NR ":" $0
        }
        if ($0 ~ /(LIBSCRIPT_ROOT_DIR|SCRIPT_DIR)[%!]\t/) {
          tab_path_hits = (tab_path_hits ? tab_path_hits "; " : "") NR ":" $0
        }
        if (tolower($0) ~ /^endlocal[[:space:]]*&[[:space:]]*\(/) {
          in_endlocal = 1
        } else if (in_endlocal && $0 ~ /^[[:space:]]*\)/) {
          in_endlocal = 0
        } else if (in_endlocal && $0 ~ /!PATH!/) {
          endlocal_delayed_hits = (endlocal_delayed_hits ? endlocal_delayed_hits "; " : "") NR ":" $0
        }
        if (tolower($0) ~ /^[[:space:]]+endlocal[[:space:]]*&&?[[:space:]]*(\(|set[[:space:]])/) {
          endlocal_delayed_hits = (endlocal_delayed_hits ? endlocal_delayed_hits "; " : "") NR ":" $0
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
        if (bad_script_dir_strip != "") print "BATCH_SCRIPT_DIR_STRIP|Corrupted SCRIPT_DIR:~-1 backslash check: " bad_script_dir_strip
        if (tab_path_hits != "") print "BATCH_TAB_CORRUPTION|Literal TAB character in path variable expansion: " tab_path_hits
        if (endlocal_delayed_hits != "") print "BATCH_ENDLOCAL_DELAYED|Delayed expansion !PATH! inside endlocal block: " endlocal_delayed_hits
        if (chained_if_else_hits != "") print "BATCH_CHAINED_IF_ELSE|Chained if ... if ... ( ... ) else ( ... ) skips else when outer if is false: " chained_if_else_hits
        if (raw_fetch_hits != "") print "RAW_NETWORK_FETCH|Raw network call in batch script (delegate to pkg_mgr.cmd): " raw_fetch_hits
        if (raw_pkg_hits != "") print "RAW_PACKAGE_MANAGER|Raw winget/choco/scoop call in batch script (delegate to pkg_mgr.cmd): " raw_pkg_hits
        if (bare_exit_hits != "") print "BATCH_HYGIENE|Bare exit without /b found in batch script: " bare_exit_hits
      }
    ' "$file" 2>/dev/null || true)
    if [ -n "$cmd_violations" ]; then
      OIFS_V="$IFS"
      IFS='
'
      for v_line in $cmd_violations; do
        v_rule="${v_line%%|*}"
        v_msg="${v_line#*|}"
        case "$v_rule" in
          RAW_NETWORK_FETCH)
            case "$file" in
              *_lib/_common/pkg_mgr.cmd|*_lib/init-systems/daemonize.cmd|*_lib/utilities/curl/test.cmd|*_lib/utilities/wget/test.cmd|*_lib/utilities/aria2/test.cmd|*devtools/*|*tests/*|cli/commands/packaging/formats/pkg_docker_compose.cmd) ;;
              *) log_failure "$file" "$v_rule" "$v_msg" ;;
            esac
            ;;
          RAW_PACKAGE_MANAGER)
            case "$file" in
              *_lib/_common/pkg_mgr.cmd|*_lib/package-managers/*|*devtools/*|*tests/*) ;;
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

  # 8b. Verify _lib/*/*/env.cmd exports across endlocal boundary and idempotent PATH updates
  case "$file" in
    _lib/*/env.cmd)
      if grep -qi "setlocal" "$file" && ! grep -qi "endlocal" "$file"; then
        log_failure "$file" "ENV_CMD_ENDLOCAL" "env.cmd uses setlocal without endlocal; PATH and variable updates will be lost on return."
      fi
      unguarded_cmd_path=$(grep -niE '^[[:space:]]*(endlocal[[:space:]]*&[[:space:]]*)?set[[:space:]]+"PATH=[^"]+;%PATH%"' "$file" 2>/dev/null || true)
      if [ -n "$unguarded_cmd_path" ]; then
        log_failure "$file" "ENV_PATH_IDEMPOTENCY" "Unguarded set \"PATH=...;%PATH%\" in env.cmd duplicates PATH entries on re-run: $unguarded_cmd_path"
      fi
      ;;
    _lib/*/env.sh)
      unguarded_sh_path=$(grep -nE '^[[:space:]]*export[[:space:]]+PATH="[^"]+:\$\{?PATH(\:-)?\}?"' "$file" 2>/dev/null || true)
      if [ -n "$unguarded_sh_path" ]; then
        log_failure "$file" "ENV_PATH_IDEMPOTENCY" "Unguarded export PATH=\"...:\$PATH\" in env.sh duplicates PATH entries on re-run: $unguarded_sh_path"
      fi
      ;;
  esac

  # 8c. Enforce Zero-Dependency Substrate in core orchestration (_lib/_common/, _lib/orchestration/, _lib/init-systems/, _lib/databases/, _lib/cloud/core/, cli/)
  case "$file" in
    _lib/_common/*.sh|_lib/orchestration/*.sh|_lib/init-systems/*.sh|_lib/databases/*.sh|_lib/cloud/core/*.sh|cli/*.sh)
      interp_hits=$(grep -nE '(^[[:space:]]*|\$\()(python3?[[:space:]]+-c|node[[:space:]]+-e|perl[[:space:]]+-e|ruby[[:space:]]+-e)[[:space:]]|libscript-allow-interp' "$file" 2>/dev/null || true)
      if [ -n "$interp_hits" ]; then
        log_failure "$file" "ZERO_DEP_SUBSTRATE" "Core orchestration script invokes external interpreter inline: $interp_hits"
      fi
      ;;
  esac

  # 8d. Ban hardcoded user/project paths and .volta in core substrate (_lib/ and cli/)
  case "$file" in
    _lib/*|cli/*)
      leak_hits=$(grep -nE '(pulse_query|pulse-query|hospital-dashboard-platform|hospital_dashboard_platform|t1d_analytics|t1d-analytics|/home/azureuser|C:\\Users\\vagrant|\.volta/bin)' "$file" 2>/dev/null || true)
      if [ -n "$leak_hits" ]; then
        log_failure "$file" "NO_HARDCODED_USER_PATHS" "Hardcoded user/project path or .volta reference in substrate: $leak_hits"
      fi
      ;;
  esac

  # 8e. Ban commented-out libscript_depends in recipe setup scripts
  case "$file" in
    _lib/*/*/setup*.sh)
      commented_dep_hits=$(grep -nE '^[[:space:]]*#[[:space:]]*#[[:space:]]*libscript_depends' "$file" 2>/dev/null || true)
      if [ -n "$commented_dep_hits" ]; then
        log_failure "$file" "COMMENTED_DEPENDS" "Commented-out '# # libscript_depends' found in recipe setup script: $commented_dep_hits"
      fi
      ;;
  esac

  # 8f. Ensure _lib/_common/env_base.cmd and pkg_mgr.sh preserve caller context and STACK hygiene
  case "$file" in
    _lib/_common/env_base.cmd)
      if ! grep -q 'CALLER_SCRIPT_DIR' "$file"; then
        log_failure "$file" "STACK_HYGIENE" "env_base.cmd must support CALLER_SCRIPT_DIR to prevent resolving PACKAGE_NAME to _common."
      fi
      ;;
    _lib/_common/pkg_mgr.sh|_lib/_common/os_info.sh)
      if ! grep -q 'STACK=.*THIS_FILE' "$file"; then
        log_failure "$file" "STACK_HYGIENE" "Common library script must pop THIS_FILE from STACK on completion."
      fi
      ;;
    _lib/*/*/env.sh)
      if grep -v '^[[:space:]]*#' "$file" | grep -Eq '\$HOME([^A-Za-z0-9_]|$)|(\$\{HOME\})'; then
        log_failure "$file" "SET_FEU_SAFETY" "Unguarded \$HOME reference in env.sh; use \${HOME:-/root} for set -u daemon safety."
      fi
      ;;
    _lib/checksums.txt)
      _cs_err=$(awk '
        /^[[:space:]]*#/ || NF == 0 { next }
        NF != 2 || $2 !~ /^[0-9a-fA-F]{64}$/ { print "line " NR ": malformed entry"; next }
        {
          if (($1 in seen) && seen[$1] != tolower($2)) {
            print "line " NR ": conflicting SHA256 for " $1
          }
          seen[$1] = tolower($2)
        }
      ' "$file" 2>/dev/null || true)
      if [ -n "$_cs_err" ]; then
        log_failure "$file" "CHECKSUM_INTEGRITY" "Invalid checksum entry: $_cs_err"
      fi
      ;;
  esac

  # 9. JSON Validity & Schema 100% Property Description Coverage
  case "$file" in
    *.json)
      if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$file" >/dev/null 2>&1; then
          log_failure "$file" "JSON_VALIDITY" "File is not syntactically valid JSON."
        fi
      fi
      ;;
  esac
  case "$file" in
    _lib/*/*/manifest.json)
      if command -v jq >/dev/null 2>&1; then
        _bad_os=$(jq -r '((.os_whitelist // []) + (.os_blacklist // []))[]' "$file" 2>/dev/null | grep -Ev '^(all|linux|macos|darwin|mac|windows|freebsd|openbsd|netbsd|dragonfly|bsd|sunos|illumos|solaris|alpine|debian|ubuntu|rhel|fedora|centos|rocky|almalinux|arch|artix|manjaro|gentoo|void|suse|opensuse|solus|clearlinux|nixos)$' || true)
        if [ -n "$_bad_os" ]; then
          log_failure "$file" "JSON_VALIDITY" "Invalid OS identifier in manifest.json: $_bad_os"
        fi
      fi
      ;;
  esac
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
  for candidate in $(git ls-files "*.sh" "*.cmd" "*.bat" "*.ps1" "*.json" "_lib/checksums.txt"); do
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
    printf '%s\n' '[AUDIT] No matching files to audit.'
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
    if [ -f "${ORIG_PWD}/${candidate}" ]; then
      audit_single_file "${ORIG_PWD}/${candidate}"
    elif [ -f "$candidate" ]; then
      audit_single_file "$candidate"
    fi
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[AUDIT] %d standards violation(s) found.\n' "$ERRORS" >&2
  exit 1
fi

printf '%s\n' '[AUDIT] All inspected files adhere to LibScript engineering standards.'
exit 0
