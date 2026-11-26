#!/bin/sh
# ## Overview
# Cross-platform POSIX `/bin/sh` Git pre-commit orchestrator executing staged normalization,
# concurrent static audits (`cspell`, `audit_standards`, `audit_posix`, `audit_tiers`,
# `audit_version_manager`, `audit_schema_vars`, `audit_stacks`, `shellcheck`, `wincheck`, `doc_coverage`),
# and parallel schema/README synchronization via `engine/common/parallel.sh`.
# ## Usage
# ./.githooks/pre-commit.sh [--all]
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
unset SCRIPT_NAME || true
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

HOOK_REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$HOOK_REPO_ROOT"

_pc_ls_bin="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bin"
if [ -d "${_pc_ls_bin}" ]; then
  case ":${PATH}:" in
    *":${_pc_ls_bin}:"*) ;;
    *) PATH="${PATH}:${_pc_ls_bin}" ;;
  esac
fi
if [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ]; then
  for _pc_fb_dir in \
    '/opt/homebrew/bin' \
    '/usr/local/bin' \
    "${HOME:-/root}/.local/bin" \
    "${HOME:-/root}/.cabal/bin"; do
    if [ -d "${_pc_fb_dir}" ]; then
      case ":${PATH}:" in
        *":${_pc_fb_dir}:"*) ;;
        *) PATH="${PATH}:${_pc_fb_dir}" ;;
      esac
    fi
  done
fi
export PATH

if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/nodejs/env.sh" ]; then
  _pc_saved_this="${THIS_FILE:-}"
  _pc_saved_dir="${SCRIPT_DIR:-}"
  _pc_saved_stack="${STACK:-}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/languages/nodejs/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  unset SCRIPT_NAME || true
  THIS_FILE="$_pc_saved_this"
  SCRIPT_DIR="$_pc_saved_dir"
  STACK="$_pc_saved_stack"
  export STACK
  unset _pc_saved_this _pc_saved_dir _pc_saved_stack || true
fi

if ! command -v jq >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
  _pc_saved_this="${THIS_FILE:-}"
  _pc_saved_dir="${SCRIPT_DIR:-}"
  _pc_saved_stack="${STACK:-}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  unset SCRIPT_NAME || true
  THIS_FILE="$_pc_saved_this"
  SCRIPT_DIR="$_pc_saved_dir"
  STACK="$_pc_saved_stack"
  export STACK
  unset _pc_saved_this _pc_saved_dir _pc_saved_stack || true
fi

# ## load_shellcheck_env
# Sources the isolated ShellCheck version manager environment while preserving caller path and recursion state.
load_shellcheck_env() {
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/shellcheck/env.sh" ]; then
    _sc_saved_this="${THIS_FILE:-}"
    _sc_saved_dir="${SCRIPT_DIR:-}"
    _sc_saved_stack="${STACK:-}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/shellcheck/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
    THIS_FILE="$_sc_saved_this"
    SCRIPT_DIR="$_sc_saved_dir"
    STACK="$_sc_saved_stack"
    export STACK
    unset _sc_saved_this _sc_saved_dir _sc_saved_stack || true
  fi
}

# ## ensure_shellcheck_bootstrapped
# Ensures shellcheck is available on PATH, bootstrapping it idempotently via LibScript when nonexistent.
ensure_shellcheck_bootstrapped() {
  load_shellcheck_env
  if command -v shellcheck >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' '[BOOTSTRAP] shellcheck not found on PATH; installing via LibScript version manager...'
  if ! (
    unset SCRIPT_NAME || true
    LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
    STACK='' \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install shellcheck "${SHELLCHECK_VERSION:-latest}"
  ); then
    printf '%s\n' '[ERROR] Failed to bootstrap shellcheck via LibScript version manager.' >&2
    return 1
  fi
  load_shellcheck_env
  if ! command -v shellcheck >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] shellcheck still not found on PATH after bootstrap.' >&2
    return 1
  fi
  return 0
}

# ## load_wincheck_env
# Sources the isolated win-cmd-rs version manager environment while preserving caller path and recursion state.
load_wincheck_env() {
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh" ]; then
    _wc_saved_this="${THIS_FILE:-}"
    _wc_saved_dir="${SCRIPT_DIR:-}"
    _wc_saved_stack="${STACK:-}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
    THIS_FILE="$_wc_saved_this"
    SCRIPT_DIR="$_wc_saved_dir"
    STACK="$_wc_saved_stack"
    export STACK
    unset _wc_saved_this _wc_saved_dir _wc_saved_stack || true
  fi
}

# ## ensure_wincheck_bootstrapped
# Ensures wincheck is available on PATH, bootstrapping win-cmd-rs idempotently via LibScript when nonexistent.
ensure_wincheck_bootstrapped() {
  load_wincheck_env
  if command -v wincheck >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' '[BOOTSTRAP] wincheck not found on PATH; installing via LibScript version manager...'
  if ! (
    unset SCRIPT_NAME || true
    LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
    STACK='' \
    "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs "${WIN_CMD_RS_VERSION:-latest}"
  ); then
    printf '%s\n' '[ERROR] Failed to bootstrap win-cmd-rs (wincheck) via LibScript version manager.' >&2
    return 1
  fi
  load_wincheck_env
  if ! command -v wincheck >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] wincheck still not found on PATH after bootstrap.' >&2
    return 1
  fi
  return 0
}

PC_WORK=$(libscript_make_tmpdir 'hook')
trap 'rm -rf "$PC_WORK"' EXIT INT TERM HUP

PC_JOBS=$(libscript_parallel_jobs)
printf 'Running pre-commit hooks (jobs=%s)...\n' "$PC_JOBS"

AUDIT_MODE='--staged'
STAGED_LIST="${PC_WORK}/STAGED.TXT"
CHECK_LIST="${PC_WORK}/CHECK.TXT"
git diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM > "$STAGED_LIST" || : > "$STAGED_LIST"

if [ "${1:-}" = '--all' ]; then
  AUDIT_MODE='--all'
  _del_f="${PC_WORK}/DELETED.TXT"
  git ls-files --deleted > "$_del_f" 2>/dev/null || : > "$_del_f"
  git ls-files --cached --others --exclude-standard \
    | awk -v del_f="$_del_f" 'BEGIN { while ((getline d < del_f) > 0) del[d] = 1; close(del_f) } NF > 0 && !($0 in del) { print }' > "$CHECK_LIST"
else
  while IFS= read -r _sf || [ -n "$_sf" ]; do
    [ -n "$_sf" ] && [ -f "$_sf" ] && printf '%s\n' "$_sf"
  done < "$STAGED_LIST" > "$CHECK_LIST"
fi

# shellcheck disable=SC2329
# ## _pc_dos2unix_batch
# Converts a batch of files to LF line endings via dos2unix.
_pc_dos2unix_batch() { dos2unix -q "$@" 2>/dev/null || true; }

# shellcheck disable=SC2329
# ## _pc_unix2dos_batch
# Converts a batch of files to CRLF line endings via unix2dos.
_pc_unix2dos_batch() { unix2dos -q "$@" 2>/dev/null || true; }

# shellcheck disable=SC2329
# ## _pc_prettier_batch
# Formats a batch of staged files with Prettier when available.
_pc_prettier_batch() {
  if command -v prettier >/dev/null 2>&1; then
    prettier --write "$@" >/dev/null 2>&1 || true
  elif [ -x "${LIBSCRIPT_ROOT_DIR}/node_modules/.bin/prettier" ]; then
    "${LIBSCRIPT_ROOT_DIR}/node_modules/.bin/prettier" --write "$@" >/dev/null 2>&1 || true
  elif [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && command -v npx >/dev/null 2>&1; then
    npx --yes prettier --write "$@" >/dev/null 2>&1 || true
  fi
}

# shellcheck disable=SC2329
# ## _pc_git_add_batch
# Re-stages normalized files in git index.
_pc_git_add_batch() { git add -- "$@" 2>/dev/null || true; }

# Wave 1: Pre-flight staged file normalization and idempotent linter bootstrap
if [ ! -s "$STAGED_LIST" ]; then
  printf '%s\n' 'No staged files to reformat.'
else
  printf '%s\n' 'Enforcing line endings and indent...'
  _tmp_crlf="${PC_WORK}/CRLF.TXT"
  _tmp_lf="${PC_WORK}/LF.TXT"
  _tmp_fmt="${PC_WORK}/FMT.TXT"
  : > "$_tmp_crlf"
  : > "$_tmp_lf"
  : > "$_tmp_fmt"

  while IFS= read -r file || [ -n "$file" ]; do
    [ -f "$file" ] || continue
    ext="${file##*.}"
    filename=$(basename "$file")
    if [ "$ext" = 'cmd' ] || [ "$ext" = 'bat' ]; then
      printf '%s\n' "$file" >> "$_tmp_crlf"
    else
      case "$filename" in
        *Dockerfile*|Makefile|.prettierrc|Vagrantfile|celery_env|ssh_config|ROOT|.gitignore|.gitattributes|.dockerignore|.editorconfig)
          printf '%s\n' "$file" >> "$_tmp_lf"
          ;;
        *)
          case "$ext" in
            sh|awk|jq|conf|service|tpl|txt|md|json|yml|yaml|py|ps1)
              printf '%s\n' "$file" >> "$_tmp_lf"
              ;;
            *)
              if [ "$file" = '.githooks/pre-commit' ]; then
                printf '%s\n' "$file" >> "$_tmp_lf"
              fi
              ;;
          esac
          ;;
      esac
    fi
    case "$ext" in
      json|yml|yaml|md) printf '%s\n' "$file" >> "$_tmp_fmt" ;;
    esac
  done < "$STAGED_LIST"

  if [ -s "$_tmp_crlf" ]; then
    if command -v dos2unix >/dev/null 2>&1 && command -v unix2dos >/dev/null 2>&1; then
      libscript_batch_exec "$_tmp_crlf" 100 _pc_dos2unix_batch
      libscript_batch_exec "$_tmp_crlf" 100 _pc_unix2dos_batch
    else
      _cf_tmp="${PC_WORK}/CRLF_ONE.TMP"
      while IFS= read -r _cf || [ -n "$_cf" ]; do
        [ -f "$_cf" ] || continue
        if tr -d '\r' < "$_cf" | awk '{ printf "%s\r\n", $0 }' > "$_cf_tmp"; then
          if ! cmp -s "$_cf_tmp" "$_cf"; then
            cat "$_cf_tmp" > "$_cf"
          fi
        fi
      done < "$_tmp_crlf"
      rm -f "$_cf_tmp"
    fi
  fi
  if [ -s "$_tmp_lf" ] && command -v dos2unix >/dev/null 2>&1; then
    libscript_batch_exec "$_tmp_lf" 100 _pc_dos2unix_batch
  fi
  if [ -s "$_tmp_fmt" ]; then
    libscript_batch_exec "$_tmp_fmt" 100 _pc_prettier_batch
  fi
  libscript_batch_exec "$STAGED_LIST" 100 _pc_git_add_batch
fi

ensure_shellcheck_bootstrapped
SHELLCHECK_OPT_ARGS=''
if shellcheck --list-optional 2>/dev/null | grep -q 'useless-use-of-cat'; then
  SHELLCHECK_OPT_ARGS='-o useless-use-of-cat'
fi

SC_LIST="${PC_WORK}/SC_FILES.TXT"
WC_LIST="${PC_WORK}/WC_FILES.TXT"
awk -v sc_out="$SC_LIST" -v wc_out="$WC_LIST" '
  NF == 0 { next }
  ($0 ~ /\.sh$/ || $0 == ".githooks/pre-commit") && $0 !~ /(^|\/)(node_modules|\.git|gen)\// { print $0 >> sc_out }
  $0 ~ /\.(cmd|bat)$/ && $0 !~ /(^|\/)(node_modules|\.git|gen|tests_tmp|cache|build)\// { print $0 >> wc_out }
' "$CHECK_LIST"

if [ -s "$WC_LIST" ]; then
  ensure_wincheck_bootstrapped
fi

# shellcheck disable=SC2329
# ## _pc_sc_chunk
# Runs shellcheck across a batch of POSIX shell script paths.
_pc_sc_chunk() {
  if [ -n "$SHELLCHECK_OPT_ARGS" ]; then
    # shellcheck disable=SC2086
    shellcheck -s sh $SHELLCHECK_OPT_ARGS "$@"
  else
    shellcheck -s sh "$@"
  fi
}

# shellcheck disable=SC2329
# ## _pc_sc_shard
# Worker processing a shard of POSIX shell scripts for shellcheck.
_pc_sc_shard() { libscript_batch_exec "$1" 60 _pc_sc_chunk; }

# shellcheck disable=SC2329
# ## _pc_wc_chunk
# Runs wincheck across a batch of Windows Batch script paths.
_pc_wc_chunk() {
  _wc_excl="${LIBSCRIPT_WINCHECK_EXCLUDE:-CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010}"
  wincheck --exclude "$_wc_excl" "$@"
}

# shellcheck disable=SC2329
# ## _pc_wc_shard
# Worker processing a shard of Windows Batch scripts for wincheck.
_pc_wc_shard() { libscript_batch_exec "$1" 80 _pc_wc_chunk; }

# shellcheck disable=SC2329
# ## _pc_cspell_shard
# Runs cspell lint against one shard of candidate file paths.
_pc_cspell_shard() {
  _pcs_f="$1"
  if [ "$CSPELL_MODE" = 'global' ]; then
    cspell lint --no-progress --no-summary --no-must-find-files --file-list "$_pcs_f" </dev/null
  elif [ "$CSPELL_MODE" = 'local' ]; then
    "${LIBSCRIPT_ROOT_DIR}/node_modules/.bin/cspell" lint --no-progress --no-summary --no-must-find-files --file-list "$_pcs_f" </dev/null
  else
    npx --yes --quiet cspell lint --no-progress --no-summary --no-must-find-files --file-list "$_pcs_f" </dev/null
  fi
}

# shellcheck disable=SC2329
# ## run_wave2_task
# Executes one independent static audit or linter stage with live output streaming.
run_wave2_task() {
  case "$1" in
    cspell)
      [ -s "$CHECK_LIST" ] || return 0
      printf '%s\n' 'Running spellcheck...'
      CSPELL_MODE=''
      if command -v cspell >/dev/null 2>&1; then
        CSPELL_MODE='global'
      elif [ -x "${LIBSCRIPT_ROOT_DIR}/node_modules/.bin/cspell" ]; then
        CSPELL_MODE='local'
      elif [ "${LIBSCRIPT_OFFLINE:-0}" != '1' ] && command -v npx >/dev/null 2>&1; then
        CSPELL_MODE='npx'
      fi
      [ -n "$CSPELL_MODE" ] || return 0
      export CSPELL_MODE
      _cs_cap=6
      if [ "$CSPELL_MODE" = 'npx' ]; then _cs_cap=1; fi
      if ! libscript_parallel_shards "$CHECK_LIST" _pc_cspell_shard "$_cs_cap"; then
        printf '%s\n' '[ERROR] Spellcheck failed. Please fix spelling errors or update .cspell.json.' >&2
        return 1
      fi
      ;;
    audit_standards)
      printf '%s\n' 'Running LibScript engineering standards audit...'
      STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_standards.sh" "$AUDIT_MODE"
      ;;
    audit_posix)
      STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_posix.sh" "$AUDIT_MODE"
      ;;
    audit_tiers)
      STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_tiers.sh" "$AUDIT_MODE"
      ;;
    audit_vm)
      if [ "$AUDIT_MODE" = '--all' ]; then
        STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_version_manager.sh"
      else
        _vm_dirs=$(awk -F'/' '$1 == "_lib" && $2 != "_common" && NF >= 3 { print $1 "/" $2 "/" $3 }' "$CHECK_LIST" | sort -u)
        if [ -n "$_vm_dirs" ]; then
          # shellcheck disable=SC2086
          STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_version_manager.sh" $_vm_dirs
        fi
      fi
      ;;
    audit_schema_vars)
      STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_schema_vars.sh" "$AUDIT_MODE"
      ;;
    audit_stacks)
      STACK='' "${HOOK_REPO_ROOT}/devtools/audit/audit_stacks.sh" --strict
      ;;
    shellcheck)
      printf '%s\n' 'Running shellcheck...'
      if [ -s "$SC_LIST" ]; then
        libscript_parallel_shards "$SC_LIST" _pc_sc_shard
      fi
      ;;
    wincheck)
      if [ -s "$WC_LIST" ]; then
        printf '%s\n' 'Running wincheck...'
        libscript_parallel_shards "$WC_LIST" _pc_wc_shard
      fi
      ;;
    doc_coverage)
      if [ "$AUDIT_MODE" = '--all' ]; then
        STACK='' "${HOOK_REPO_ROOT}/devtools/audit/doc_coverage.sh" --strict
      else
        STACK='' "${HOOK_REPO_ROOT}/devtools/audit/doc_coverage.sh" --strict --staged
      fi
      ;;
  esac
}

# Wave 2: Concurrent read-only audits & linters
WAVE2_FILE="${PC_WORK}/WAVE2.TXT"
: > "$WAVE2_FILE"
if [ -s "$CHECK_LIST" ]; then
  printf '%s\n' 'cspell' >> "$WAVE2_FILE"
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/audit_standards.sh" ]; then
  printf '%s\n' 'audit_standards' >> "$WAVE2_FILE"
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/audit_posix.sh" ]; then
  printf '%s\n' 'audit_posix' >> "$WAVE2_FILE"
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/audit_tiers.sh" ]; then
  printf '%s\n' 'audit_tiers' >> "$WAVE2_FILE"
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/audit_version_manager.sh" ]; then
  if [ "$AUDIT_MODE" = '--all' ] || grep -q '^_lib/' "$CHECK_LIST" 2>/dev/null; then
    printf '%s\n' 'audit_vm' >> "$WAVE2_FILE"
  fi
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/audit_schema_vars.sh" ]; then
  if [ "$AUDIT_MODE" = '--all' ] || grep -qE '^(_lib/|.*\.schema\.json$)' "$CHECK_LIST" 2>/dev/null; then
    printf '%s\n' 'audit_schema_vars' >> "$WAVE2_FILE"
  fi
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/audit_stacks.sh" ]; then
  if [ "$AUDIT_MODE" = '--all' ] || grep -q '^workloads/' "$CHECK_LIST" 2>/dev/null; then
    printf '%s\n' 'audit_stacks' >> "$WAVE2_FILE"
  fi
fi
printf '%s\n' 'shellcheck' >> "$WAVE2_FILE"
if [ -s "$WC_LIST" ]; then
  printf '%s\n' 'wincheck' >> "$WAVE2_FILE"
fi
if [ -x "${HOOK_REPO_ROOT}/devtools/audit/doc_coverage.sh" ]; then
  printf '%s\n' 'doc_coverage' >> "$WAVE2_FILE"
fi

if ! libscript_parallel_map "$WAVE2_FILE" run_wave2_task; then
  printf '%s\n' '[ERROR] One or more concurrent pre-commit audits failed.' >&2
  exit 1
fi

# Wave 3: Parallel + staged fast-path Markdown & README table synchronization
NEED_GMD=0
NEED_UR=0
if [ "$AUDIT_MODE" = '--all' ]; then
  NEED_GMD=1
  NEED_UR=1
elif [ -s "$CHECK_LIST" ]; then
  if grep -qE '(^|/)(vars\.schema\.json|base_vars\.schema\.json|schemas/vars/.*\.schema\.json|devtools/docs-gen/.*|(_lib|workloads|topologies|payloads)/.*README\.md|engine/common/README\.md)$' "$CHECK_LIST"; then
    NEED_GMD=1
  fi
  if grep -qE '(^|/)(manifest\.json|README\.md|TODO_PLAN\.md|TESTING_TODO_PLAN\.md|tests/update_results\.(sh|cmd|ps1))$' "$CHECK_LIST"; then
    NEED_UR=1
  fi
fi

# shellcheck disable=SC2329
# ## run_wave3_task
# Runs disjoint documentation generators (component READMEs vs root README matrix) concurrently.
run_wave3_task() {
  case "$1" in
    gmd)
      printf '%s\n' 'Regenerating markdown readme files interpolating the json...'
      STACK='' "${HOOK_REPO_ROOT}/devtools/docs-gen/generate_markdown_docs.sh"
      ;;
    ur)
      printf '%s\n' 'Updating Supported Components in README.md...'
      STACK='' "${HOOK_REPO_ROOT}/tests/update_results.sh"
      ;;
  esac
}

WAVE3_FILE="${PC_WORK}/WAVE3.TXT"
: > "$WAVE3_FILE"
if [ "$NEED_GMD" -eq 1 ] && [ -x "${HOOK_REPO_ROOT}/devtools/docs-gen/generate_markdown_docs.sh" ]; then
  printf '%s\n' 'gmd' >> "$WAVE3_FILE"
fi
if [ "$NEED_UR" -eq 1 ] && [ -x "${HOOK_REPO_ROOT}/tests/update_results.sh" ]; then
  printf '%s\n' 'ur' >> "$WAVE3_FILE"
fi

if [ -s "$WAVE3_FILE" ]; then
  libscript_parallel_map "$WAVE3_FILE" run_wave3_task 2
fi

if [ "$NEED_GMD" -eq 1 ]; then
  _mod_rm_list="${PC_WORK}/MOD_RM.TXT"
  git ls-files -m | grep 'README\.md$' > "$_mod_rm_list" 2>/dev/null || : > "$_mod_rm_list"
  if [ -s "$_mod_rm_list" ]; then
    printf '%s\n' 'Formatting modified README.md files...'
    if command -v dos2unix >/dev/null 2>&1; then
      libscript_batch_exec "$_mod_rm_list" 100 _pc_dos2unix_batch
    fi
    libscript_batch_exec "$_mod_rm_list" 100 _pc_prettier_batch
    if [ -s "$STAGED_LIST" ]; then
      libscript_batch_exec "$_mod_rm_list" 100 _pc_git_add_batch
    fi
  fi
fi

if [ -x "${HOOK_REPO_ROOT}/devtools/audit/doc_coverage.sh" ] && [ -f "${HOOK_REPO_ROOT}/README.md" ]; then
  if ! grep -q '\[!\[Doc Coverage\](https://img\.shields\.io/badge/doc%20coverage-100%25-brightgreen\.svg)' "${HOOK_REPO_ROOT}/README.md" 2>/dev/null; then
    printf '%s\n' 'Updating Doc Coverage shield in README.md...'
    STACK='' "${HOOK_REPO_ROOT}/devtools/audit/doc_coverage.sh" --update-readme
  fi
fi

if [ -f 'README.md' ] && ! git diff --quiet -- README.md 2>/dev/null; then
  printf '%s\n' 'Formatting README.md...'
  if command -v dos2unix >/dev/null 2>&1; then
    dos2unix -q README.md 2>/dev/null || true
  fi
  _pc_prettier_batch README.md
  if [ -s "$STAGED_LIST" ]; then
    git add README.md
  fi
fi

printf '%s\n' 'Pre-commit hook completed successfully.'
