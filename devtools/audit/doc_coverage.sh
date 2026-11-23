#!/bin/sh
# ## Overview
# Audits documentation coverage of component README.md files, schema keys, CLI flags,
# shell functions, and script header comments (.sh, .cmd, .ps1), and optionally updates
# the % doc coverage shield in README.md.
# ## Usage
#   ./devtools/audit/doc_coverage.sh [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT]

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

# ## show_help
# Displays command-line usage instructions and available options.
show_help() {
  printf '%s\n' "Usage: $(basename "$THIS_FILE") [--strict] [--update-readme [README_PATH]] [--repo-root REPO_ROOT] [--help]"
  printf '%s\n' 'Audits documentation coverage and updates the % doc coverage shield in README.md.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --strict                       Fail with exit code 1 if coverage is below 100%.'
  printf '%s\n' '  --update-readme [README_PATH]  Update the Doc Coverage shield in README.md.'
  printf '%s\n' '  --repo-root REPO_ROOT          Override repository root directory.'
  printf '%s\n' '  --help, -h, /?, -?             Show this help message.'
}

UPDATE_README=0
STAGED_ONLY=0
README_FILE=''
TARGET_ROOT="${LIBSCRIPT_ROOT_DIR}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h|'/?'|'-?')
      show_help
      exit 0
      ;;
    --strict)
      shift
      ;;
    --staged)
      STAGED_ONLY=1
      shift
      ;;
    --update-readme)
      UPDATE_README=1
      if [ "$#" -gt 1 ]; then
        case "$2" in
          --*) shift ;;
          *) README_FILE="$2"; shift 2 ;;
        esac
      else
        shift
      fi
      ;;
    --repo-root)
      if [ "$#" -gt 1 ]; then
        TARGET_ROOT="$2"
        shift 2
      else
        shift
      fi
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$README_FILE" ]; then
  README_FILE="${TARGET_ROOT}/README.md"
fi

DC_WORK=$(libscript_make_tmpdir 'docs')
trap 'rm -rf "$DC_WORK"' EXIT INT TERM

# ## update_readme_shield
# Inserts or updates the Doc Coverage shield badge in the target README.md file.
update_readme_shield() {
  _readme="$1"
  _pct="$2"
  [ -f "$_readme" ] || return 0

  _color='brightgreen'
  if [ "$_pct" -lt 100 ]; then
    if [ "$_pct" -ge 80 ]; then
      _color='yellow'
    else
      _color='red'
    fi
  fi

  _shield="[![Doc Coverage](https://img.shields.io/badge/doc%20coverage-${_pct}%25-${_color}.svg)](DOCS_ROADMAP.md)"
  _tmp_readme="${DC_WORK}/README_SHIELD.TMP"

  if grep -q '\[!\[Doc Coverage\](https://img\.shields\.io/badge/doc%20coverage-' "$_readme"; then
    awk -v shield="$_shield" '
      /\[!\[Doc Coverage\]\(https:\/\/img\.shields\.io\/badge\/doc%20coverage-/ {
        print shield
        next
      }
      { print }
    ' "$_readme" > "$_tmp_readme"
  elif grep -q '\[!\[CI Tests\](' "$_readme"; then
    awk -v shield="$_shield" '
      /\[!\[CI Tests\]\(/ {
        print
        print shield
        next
      }
      { print }
    ' "$_readme" > "$_tmp_readme"
  elif grep -q '\[!\[License\](' "$_readme"; then
    awk -v shield="$_shield" '
      /\[!\[License\]\(/ {
        print
        print shield
        next
      }
      { print }
    ' "$_readme" > "$_tmp_readme"
  else
    {
      printf '%s\n' "$_shield"
      cat "$_readme"
    } > "$_tmp_readme"
  fi

  if ! cmp -s "$_tmp_readme" "$_readme"; then
    mv "$_tmp_readme" "$_readme"
  else
    rm -f "$_tmp_readme"
  fi
}

# ## filter_existing_rel_paths
# Filters newline-delimited relative paths under TARGET_ROOT to existing regular files.
filter_existing_rel_paths() {
  _fer_in="$1"
  _fer_out="$2"
  : > "$_fer_out"
  [ -s "$_fer_in" ] || return 0
  if ! git -C "${TARGET_ROOT}" diff --name-only --diff-filter=D >/dev/null 2>&1; then
    while IFS= read -r _fer_p || [ -n "$_fer_p" ]; do
      if [ -f "${TARGET_ROOT}/${_fer_p}" ]; then
        printf '%s\n' "$_fer_p"
      fi
    done < "$_fer_in" > "$_fer_out"
    return 0
  fi
  _fer_del="${DC_WORK}/DELETED.TXT"
  git -C "${TARGET_ROOT}" ls-files --deleted > "$_fer_del" 2>/dev/null || : > "$_fer_del"
  if [ ! -s "$_fer_del" ]; then
    cp "$_fer_in" "$_fer_out"
  else
    awk 'NR == FNR { del[$0] = 1; next } !($0 in del) { print }' "$_fer_del" "$_fer_in" > "$_fer_out"
  fi
}

if [ "$STAGED_ONLY" -eq 1 ] && [ -d "${TARGET_ROOT}/.git" ] && git -C "${TARGET_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  : > "${DC_WORK}/ALL_SCRIPTS.TXT"
  : > "${DC_WORK}/SCHEMAS.TXT"
  git -C "${TARGET_ROOT}" diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM -- '*.sh' '*.cmd' '*.bat' '*.ps1'     | grep -vE '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/'     | while IFS= read -r _sp || [ -n "$_sp" ]; do
      [ -f "${TARGET_ROOT}/${_sp}" ] && printf '%s\n' "$_sp"
    done > "${DC_WORK}/ALL_SCRIPTS.TXT" || true
  awk -v root="${TARGET_ROOT}/" -v d="${DC_WORK}" '
    /\.sh$/ { print root $0 >> (d "/SH.TXT"); next }
    /\.(cmd|bat)$/ { print root $0 >> (d "/CMD.TXT"); next }
    /\.ps1$/ { print root $0 >> (d "/PS1.TXT"); next }
  ' "${DC_WORK}/ALL_SCRIPTS.TXT"
  git -C "${TARGET_ROOT}" diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM -- '*.schema.json'     | grep -vE '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/'     | while IFS= read -r _scp || [ -n "$_scp" ]; do
      [ -f "${TARGET_ROOT}/${_scp}" ] && printf '%s/%s\n' "${TARGET_ROOT}" "$_scp"
    done > "${DC_WORK}/SCHEMAS.TXT" || true
elif [ -d "${TARGET_ROOT}/.git" ] && git -C "${TARGET_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  _raw_scripts="${DC_WORK}/RAW_SCRIPTS.TXT"
  git -C "${TARGET_ROOT}" ls-files --cached --others --exclude-standard '*.sh' '*.cmd' '*.bat' '*.ps1' \
    | grep -vE '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/' > "$_raw_scripts" || true
  filter_existing_rel_paths "$_raw_scripts" "${DC_WORK}/ALL_SCRIPTS.TXT"
  awk -v root="${TARGET_ROOT}/" -v d="${DC_WORK}" '
    /\.sh$/ { print root $0 >> (d "/SH.TXT"); next }
    /\.(cmd|bat)$/ { print root $0 >> (d "/CMD.TXT"); next }
    /\.ps1$/ { print root $0 >> (d "/PS1.TXT"); next }
  ' "${DC_WORK}/ALL_SCRIPTS.TXT"

  _raw_schemas="${DC_WORK}/RAW_SCHEMAS.TXT"
  git -C "${TARGET_ROOT}" ls-files --cached --others --exclude-standard '*.schema.json' \
    | grep -vE '^(\.git|gen|cache|tmp|tests_tmp|node_modules|vagrant)/' > "$_raw_schemas" || true
  filter_existing_rel_paths "$_raw_schemas" "${DC_WORK}/REL_SCHEMAS.TXT"
  awk -v root="${TARGET_ROOT}/" '{ print root $0 }' "${DC_WORK}/REL_SCHEMAS.TXT" > "${DC_WORK}/SCHEMAS.TXT"
else
  (
    cd "${TARGET_ROOT}"
    find . -prune -o -type f \( -name '*.sh' -o -name '*.cmd' -o -name '*.bat' -o -name '*.ps1' \) -print 2>/dev/null \
      | awk -F'/' 'NF <= 3' \
      | grep -vE '^\./(\.git|creds|node_modules|\.venv|logs|test)/' \
      | sed 's|^\./||'
  ) > "${DC_WORK}/ALL_SCRIPTS.TXT" || true

  if [ "$STAGED_ONLY" -eq 1 ] && [ -d "${TARGET_ROOT}/.git" ]; then
    _st_comps=$(git -C "${TARGET_ROOT}" diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM | awk -F/ '$1 == "_lib" && $2 != "_common" && NF >= 3 { print $1 "/" $2 "/" $3 }' | sort -u || true)
    for _sc_rel in $_st_comps; do
      _comp_dir="${TARGET_ROOT}/${_sc_rel}"
      [ -d "$_comp_dir" ] || continue
      _tc=$((_tc + 1))
      if [ ! -f "${_comp_dir}/README.md" ]; then
        printf '[WARN] Component %s is missing README.md\n' "$_sc_rel"
        _mc=$((_mc + 1))
      fi
    done
  elif [ -d "${TARGET_ROOT}/_lib" ]; then
    find "${TARGET_ROOT}" -name '*.schema.json' -type f > "${DC_WORK}/SCHEMAS.TXT" 2>/dev/null || true
    find "${TARGET_ROOT}" -name '*.sh' -type f | grep -v 'node_modules' > "${DC_WORK}/SH.TXT" 2>/dev/null || true
    find "${TARGET_ROOT}" \( -name '*.cmd' -o -name '*.bat' \) -type f | grep -v 'node_modules' > "${DC_WORK}/CMD.TXT" 2>/dev/null || true
    find "${TARGET_ROOT}" -name '*.ps1' -type f | grep -v 'node_modules' > "${DC_WORK}/PS1.TXT" 2>/dev/null || true
  else
    (cd "${TARGET_ROOT}" && find . -type f -name '*.schema.json' | awk -F'/' 'NF <= 2' | sed "s|^\\.|${TARGET_ROOT}|") > "${DC_WORK}/SCHEMAS.TXT" 2>/dev/null || true
    (cd "${TARGET_ROOT}" && find . -type f -name '*.sh' | awk -F'/' 'NF <= 3' | grep -vE '^\./(\.git|creds|node_modules|\.venv|logs|test)/' | sed "s|^\\.|${TARGET_ROOT}|") > "${DC_WORK}/SH.TXT" 2>/dev/null || true
    (cd "${TARGET_ROOT}" && find . -type f \( -name '*.cmd' -o -name '*.bat' \) | awk -F'/' 'NF <= 3' | grep -vE '^\./(\.git|creds|node_modules|\.venv|logs|test)/' | sed "s|^\\.|${TARGET_ROOT}|") > "${DC_WORK}/CMD.TXT" 2>/dev/null || true
    (cd "${TARGET_ROOT}" && find . -type f -name '*.ps1' | awk -F'/' 'NF <= 2' | sed "s|^\\.|${TARGET_ROOT}|") > "${DC_WORK}/PS1.TXT" 2>/dev/null || true
  fi
fi

# shellcheck disable=SC2329
# ## _dc_hdr_batch
# Checks a batch of relative script paths for ## Overview and ## Usage within the first 30 lines.
_dc_hdr_batch() {
  (
    cd "${TARGET_ROOT}"
    awk '
      FNR == 1 {
        if (prev_f != "" && (!ov || !us || bad)) {
          print prev_f
        }
        prev_f = FILENAME
        ov = 0; us = 0; bad = 0
      }
      FNR <= 30 {
        if ($0 ~ /## Overview/) ov = 1
        if ($0 ~ /## Usage/) us = 1
        if ($0 ~ /Performs the .* operation and updates component state\./) bad = 1
      }
      END {
        if (prev_f != "" && (!ov || !us || bad)) {
          print prev_f
        }
      }
    ' "$@" >> "${DC_HDR_SHARD_OUT}"
  )
}

# shellcheck disable=SC2329
# ## _dc_hdr_shard_worker
# Worker processing a shard of script paths for header docstring coverage.
_dc_hdr_shard_worker() {
  _dhs_shard="$1"
  DC_HDR_SHARD_OUT="${_dhs_shard}.err"
  : > "$DC_HDR_SHARD_OUT"
  libscript_batch_exec "$_dhs_shard" 250 _dc_hdr_batch
}

# shellcheck disable=SC2329
# ## _dc_schema_batch
# Checks a batch of *.schema.json files for missing or placeholder descriptions in one awk pass.
_dc_schema_batch() {
  awk -v root="${TARGET_ROOT}/" '
    BEGIN {} function flush_sch(f,   rel) {
      if (f == "") return
      rel = f; sub("^" root, "", rel)
      if (has_type && !has_desc) {
        print "M\t" rel
      } else if (has_ph) {
        print "P\t" rel
      }
    }
    FNR == 1 {
      if (prev_f != "") flush_sch(prev_f)
      prev_f = FILENAME
      has_type = 0; has_desc = 0; has_ph = 0
    }
    /"type":/ { has_type = 1 }
    /"description":/ {
      has_desc = 1
      if ($0 ~ /"description":[[:space:]]*"Variable [A-Za-z0-9_]+\.?"/) has_ph = 1
    }
    END {
      if (prev_f != "") flush_sch(prev_f)
    }
  ' "$@" >> "${DC_WORK}/SCHEMA_ERR.TXT"
}

# shellcheck disable=SC2329
# ## _dc_sh_batch
# Checks a batch of .sh files for function docstring coverage.
_dc_sh_batch() {
  awk -v root="${TARGET_ROOT}/" '
    FNR == 1 { has_doc = 0; prev_hdr = ""; rel = FILENAME; sub("^" root, "", rel) }
    /^[[:space:]]*# ## / {
      if ($0 == prev_hdr) {
        print rel "\t" rel ":" FNR " (duplicate docstring header)"
      }
      prev_hdr = $0
      has_doc = 1
      next
    }
    /^[[:space:]]*# (Executes .* (functionality|logic)|Performs the .* operation and updates component state)\.$/ {
      print rel "\t" rel ":" FNR " (placeholder docstring)"
    }
    /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(\) *\{/ {
      if (!has_doc) {
        print rel "\t" rel ":" FNR
      }
      has_doc = 0
      prev_hdr = ""
      next
    }
    /^[[:space:]]*#/ || NF == 0 { next }
    { has_doc = 0; prev_hdr = "" }
  ' "$@" >> "${DC_SH_SHARD_OUT}"
}

# shellcheck disable=SC2329
# ## _dc_sh_shard_worker
# Worker processing a shard of .sh files for function docstrings.
_dc_sh_shard_worker() {
  _dss_shard="$1"
  DC_SH_SHARD_OUT="${_dss_shard}.err"
  : > "$DC_SH_SHARD_OUT"
  libscript_batch_exec "$_dss_shard" 250 _dc_sh_batch
}

# shellcheck disable=SC2329
# ## _dc_cmd_batch
# Checks a batch of .cmd/.bat files for subroutine label docstring coverage.
_dc_cmd_batch() {
  awk -v root="${TARGET_ROOT}/" '
    FNR == 1 { has_doc = 0; prev_hdr = ""; rel = FILENAME; sub("^" root, "", rel) }
    { sub(/\r$/, "", $0) }
    /^[[:space:]]*:: ## / {
      if ($0 == prev_hdr) {
        print rel "\t" rel ":" FNR " (duplicate docstring header)"
      }
      prev_hdr = $0
      has_doc = 1
      next
    }
    /^[[:space:]]*:: (Executes .* (functionality|logic)|Performs the .* operation and updates component state)\.$/ {
      print rel "\t" rel ":" FNR " (placeholder docstring)"
    }
    /^[[:space:]]*:[A-Za-z0-9_.-]+/ && !/^[[:space:]]*:EOF([[:space:]]|$)/ && !/^[[:space:]]*:eof([[:space:]]|$)/ && !/^[[:space:]]*:root_found([[:space:]]|$)/ && !/^[[:space:]]*:find_root([[:space:]]|$)/ {
      if (!has_doc) {
        print rel "\t" rel ":" FNR
      }
      has_doc = 0
      prev_hdr = ""
      next
    }
    /^[[:space:]]*::/ || NF == 0 { next }
    { has_doc = 0; prev_hdr = "" }
  ' "$@" >> "${DC_CMD_SHARD_OUT}"
}

# shellcheck disable=SC2329
# ## _dc_cmd_shard_worker
# Worker processing a shard of .cmd/.bat files for label docstrings.
_dc_cmd_shard_worker() {
  _dcs_shard="$1"
  DC_CMD_SHARD_OUT="${_dcs_shard}.err"
  : > "$DC_CMD_SHARD_OUT"
  libscript_batch_exec "$_dcs_shard" 250 _dc_cmd_batch
}

# shellcheck disable=SC2329
# ## _dc_ps1_batch
# Checks a batch of .ps1 files for header and function docstring coverage in one awk pass.
_dc_ps1_batch() {
  awk -v root="${TARGET_ROOT}/" '
    BEGIN {} function flush_ps1(f,   rel) {
      if (f == "") return
      rel = f; sub("^" root, "", rel)
      if (!ov) print "OV\t" rel
      else if (!us) print "US\t" rel
      if (fn_hits != "") print "FN\t" rel "\t" fn_hits
    }
    FNR == 1 {
      if (prev_f != "") flush_ps1(prev_f)
      prev_f = FILENAME
      ov = 0; us = 0; has_doc = 0; in_here_str = 0; fn_hits = ""
      cur_rel = FILENAME; sub("^" root, "", cur_rel)
    }
    { sub(/\r$/, "", $0) }
    FNR <= 30 {
      if ($0 ~ /## Overview/) ov = 1
      if ($0 ~ /## Usage/) us = 1
    }
    in_here_str {
      if ($0 ~ /^"@/ || $0 ~ /^\x27@/) in_here_str = 0
      next
    }
    /@"$/ || /@\x27$/ { in_here_str = 1; next }
    /^[[:space:]]*#[[:space:]]*##[[:space:]]+/ { has_doc = 1; next }
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*function[[:space:]]+[A-Za-z0-9_-]+/ {
      if (!has_doc) fn_hits = (fn_hits ? fn_hits "; " : "") cur_rel ":" FNR ":" $0
      has_doc = 0
      next
    }
    /^[[:space:]]*$/ { next }
    { has_doc = 0 }
    END {
      if (prev_f != "") flush_ps1(prev_f)
    }
  ' "$@" >> "${DC_WORK}/PS1_ERR.TXT"
}

# shellcheck disable=SC2329
# ## run_comp_readme_pass
# Audits _lib/*/* component directories for README.md presence.
run_comp_readme_pass() {
  printf '==> Auditing Component README.md Coverage...\n'
  _tc=0
  _mc=0
  set +f
  if [ "$STAGED_ONLY" -eq 1 ] && [ -d "${TARGET_ROOT}/.git" ]; then
    _st_comps=$(git -C "${TARGET_ROOT}" diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM | awk -F/ '$1 == "_lib" && $2 != "_common" && NF >= 3 { print $1 "/" $2 "/" $3 }' | sort -u || true)
    for _sc_rel in $_st_comps; do
      _comp_dir="${TARGET_ROOT}/${_sc_rel}"
      [ -d "$_comp_dir" ] || continue
      _tc=$((_tc + 1))
      if [ ! -f "${_comp_dir}/README.md" ]; then
        printf '[WARN] Component %s is missing README.md\n' "$_sc_rel"
        _mc=$((_mc + 1))
      fi
    done
  elif [ -d "${TARGET_ROOT}/_lib" ]; then
    for _cat_dir in "${TARGET_ROOT}/_lib"/*; do
      [ -d "$_cat_dir" ] || continue
      [ "$(basename "$_cat_dir")" = '_common' ] && continue
      for _comp_dir in "$_cat_dir"/*; do
        [ -d "$_comp_dir" ] || continue
        [ "$(basename "$_comp_dir")" = '_common' ] && continue
        _tc=$((_tc + 1))
        if [ ! -f "${_comp_dir}/README.md" ]; then
          printf '[WARN] Component %s is missing README.md\n' "${_comp_dir#"${TARGET_ROOT}"/}"
          _mc=$((_mc + 1))
        fi
      done
    done
  fi
  set -f
  printf '%d %d\n' "$_tc" "$_mc" > "${DC_WORK}/COMP.CNT"
}

# shellcheck disable=SC2329
# ## run_script_header_pass
# Audits script files for ## Overview and ## Usage headers across parallel shards.
run_script_header_pass() {
  printf '==> Auditing Script Header Markdown Docstring Coverage (.sh, .cmd, .bat, .ps1)...\n'
  _ts=0
  _ms=0
  if [ -s "${DC_WORK}/ALL_SCRIPTS.TXT" ]; then
    _ts=$(wc -l < "${DC_WORK}/ALL_SCRIPTS.TXT" | tr -d ' ')
    DC_HDR_SHARD_OUT="${DC_WORK}/HDR_ERR.TXT"
    : > "$DC_HDR_SHARD_OUT"
    if [ "$_ts" -gt 400 ]; then
      _hdr_dir="${DC_WORK}/hdr_shards"
      mkdir -p "$_hdr_dir"
      _jobs=$(libscript_parallel_jobs)
      awk -v n="$_jobs" -v d="$_hdr_dir" 'NF > 0 { idx = (c % n) + 1; c++; out = d "/S" idx ".TXT"; print $0 >> out; close(out) }' "${DC_WORK}/ALL_SCRIPTS.TXT"
      _pids=''
      _i=1
      while [ "$_i" -le "$_jobs" ]; do
        if [ -s "${_hdr_dir}/S${_i}.TXT" ]; then
          ( _dc_hdr_shard_worker "${_hdr_dir}/S${_i}.TXT" ) &
          _pids="${_pids} $!"
        fi
        _i=$((_i + 1))
      done
      for _p in $_pids; do wait "$_p" || true; done
      set +f
      for _ef in "${_hdr_dir}"/*.err; do
        [ -s "$_ef" ] && cat "$_ef" >> "$DC_HDR_SHARD_OUT"
      done
      set -f
    else
      libscript_batch_exec "${DC_WORK}/ALL_SCRIPTS.TXT" 250 _dc_hdr_batch
    fi
    if [ -s "$DC_HDR_SHARD_OUT" ]; then
      awk '{ print "[WARN] Missing or placeholder markdown header comments (## Overview / ## Usage) in " $0 }' "$DC_HDR_SHARD_OUT"
      _ms=$(wc -l < "$DC_HDR_SHARD_OUT" | tr -d ' ')
    fi
  fi
  printf '%d %d\n' "$_ts" "$_ms" > "${DC_WORK}/HDR.CNT"
}

# shellcheck disable=SC2329
# ## run_schema_doc_pass
# Audits *.schema.json files for missing or placeholder descriptions.
run_schema_doc_pass() {
  printf '==> Auditing Schema Description Coverage...\n'
  _msc=0
  : > "${DC_WORK}/SCHEMA_ERR.TXT"
  if [ -s "${DC_WORK}/SCHEMAS.TXT" ]; then
    libscript_batch_exec "${DC_WORK}/SCHEMAS.TXT" 250 _dc_schema_batch
    if [ -s "${DC_WORK}/SCHEMA_ERR.TXT" ]; then
      awk -F'\t' '
        $1 == "M" { print "[WARN] Schema file " $2 " might be missing descriptions." }
        $1 == "P" { print "[WARN] Schema file " $2 " contains placeholder \"Variable <NAME>.\" description(s)." }
      ' "${DC_WORK}/SCHEMA_ERR.TXT"
      _msc=$(wc -l < "${DC_WORK}/SCHEMA_ERR.TXT" | tr -d ' ')
    fi
  fi
  printf '%d\n' "$_msc" > "${DC_WORK}/SCH.CNT"
}

# shellcheck disable=SC2329
# ## run_sh_func_pass
# Audits .sh files for function docstrings across parallel shards.
run_sh_func_pass() {
  printf '==> Auditing Shell Function Docstring Coverage...\n'
  _msh=0
  if [ -f "${DC_WORK}/SH.TXT" ] && [ -s "${DC_WORK}/SH.TXT" ]; then
    DC_SH_SHARD_OUT="${DC_WORK}/SH_ERR.TXT"
    : > "$DC_SH_SHARD_OUT"
    _sh_dir="${DC_WORK}/sh_shards"
    mkdir -p "$_sh_dir"
    _jobs=$(libscript_parallel_jobs)
    if [ "$_jobs" -gt 1 ]; then
      awk -v n="$_jobs" -v d="$_sh_dir" 'NF > 0 { idx = (c % n) + 1; c++; out = d "/S" idx ".TXT"; print $0 >> out; close(out) }' "${DC_WORK}/SH.TXT"
      _pids=''
      _i=1
      while [ "$_i" -le "$_jobs" ]; do
        if [ -s "${_sh_dir}/S${_i}.TXT" ]; then
          ( _dc_sh_shard_worker "${_sh_dir}/S${_i}.TXT" ) &
          _pids="${_pids} $!"
        fi
        _i=$((_i + 1))
      done
      for _p in $_pids; do wait "$_p" || true; done
      set +f
      for _ef in "${_sh_dir}"/*.err; do
        [ -s "$_ef" ] && cat "$_ef" >> "$DC_SH_SHARD_OUT"
      done
      set -f
    else
      libscript_batch_exec "${DC_WORK}/SH.TXT" 250 _dc_sh_batch
    fi
    if [ -s "$DC_SH_SHARD_OUT" ]; then
      awk -F'\t' '{ print "[WARN] Missing or invalid function docstring(s) in " $1 ":\n" $2 }' "$DC_SH_SHARD_OUT"
      _msh=$(cut -f1 "$DC_SH_SHARD_OUT" | sort -u | wc -l | tr -d ' ')
    fi
  fi
  printf '%d\n' "$_msh" > "${DC_WORK}/SH.CNT"
}

# shellcheck disable=SC2329
# ## run_cmd_label_pass
# Audits .cmd/.bat files for subroutine label docstrings across parallel shards.
run_cmd_label_pass() {
  printf '==> Auditing Batch Label Docstring Coverage...\n'
  _miss_cmd=0
  if [ -f "${DC_WORK}/CMD.TXT" ] && [ -s "${DC_WORK}/CMD.TXT" ]; then
    DC_CMD_SHARD_OUT="${DC_WORK}/CMD_ERR.TXT"
    : > "$DC_CMD_SHARD_OUT"
    _cmd_dir="${DC_WORK}/cmd_shards"
    mkdir -p "$_cmd_dir"
    _jobs=$(libscript_parallel_jobs)
    if [ "$_jobs" -gt 1 ]; then
      awk -v n="$_jobs" -v d="$_cmd_dir" 'NF > 0 { idx = (c % n) + 1; c++; out = d "/S" idx ".TXT"; print $0 >> out; close(out) }' "${DC_WORK}/CMD.TXT"
      _pids=''
      _i=1
      while [ "$_i" -le "$_jobs" ]; do
        if [ -s "${_cmd_dir}/S${_i}.TXT" ]; then
          ( _dc_cmd_shard_worker "${_cmd_dir}/S${_i}.TXT" ) &
          _pids="${_pids} $!"
        fi
        _i=$((_i + 1))
      done
      for _p in $_pids; do wait "$_p" || true; done
      set +f
      for _ef in "${_cmd_dir}"/*.err; do
        [ -s "$_ef" ] && cat "$_ef" >> "$DC_CMD_SHARD_OUT"
      done
      set -f
    else
      libscript_batch_exec "${DC_WORK}/CMD.TXT" 250 _dc_cmd_batch
    fi
    if [ -s "$DC_CMD_SHARD_OUT" ]; then
      awk -F'\t' '{ print "[WARN] Missing or invalid label docstring(s) in " $1 ":\n" $2 }' "$DC_CMD_SHARD_OUT"
      _miss_cmd=$(cut -f1 "$DC_CMD_SHARD_OUT" | sort -u | wc -l | tr -d ' ')
    fi
  fi
  printf '%d\n' "$_miss_cmd" > "${DC_WORK}/CMD.CNT"
}

# shellcheck disable=SC2329
# ## run_ps1_doc_pass
# Audits .ps1 files for header and function docstrings.
run_ps1_doc_pass() {
  printf '==> Auditing PowerShell Header Coverage...\n'
  _mps1=0
  : > "${DC_WORK}/PS1_ERR.TXT"
  if [ -f "${DC_WORK}/PS1.TXT" ] && [ -s "${DC_WORK}/PS1.TXT" ]; then
    libscript_batch_exec "${DC_WORK}/PS1.TXT" 250 _dc_ps1_batch
    if [ -s "${DC_WORK}/PS1_ERR.TXT" ]; then
      awk -F'\t' '
        $1 == "OV" { print "[WARN] Missing ## Overview in " $2 }
        $1 == "US" { print "[WARN] Missing ## Usage in " $2 }
        $1 == "FN" { print "[WARN] Missing PowerShell function docstring(s) in " $2 ":\n" $3 }
      ' "${DC_WORK}/PS1_ERR.TXT"
      _mps1=$(wc -l < "${DC_WORK}/PS1_ERR.TXT" | tr -d ' ')
    fi
  fi
  printf '%d\n' "$_mps1" > "${DC_WORK}/PS1.CNT"
}

# shellcheck disable=SC2329
# ## dispatch_doc_pass
# Dispatches one named documentation coverage pass for parallel execution.
dispatch_doc_pass() {
  case "$1" in
    comp) run_comp_readme_pass ;;
    hdr) run_script_header_pass ;;
    sch) run_schema_doc_pass ;;
    sh) run_sh_func_pass ;;
    cmd) run_cmd_label_pass ;;
    ps1) run_ps1_doc_pass ;;
  esac
}

PASSES_FILE="${DC_WORK}/PASSES.TXT"
printf '%s\n' 'comp' 'hdr' 'sch' 'sh' 'cmd' 'ps1' > "$PASSES_FILE"
libscript_parallel_map "$PASSES_FILE" dispatch_doc_pass 6

read -r TOTAL_COMPS MISSING_COMP_READMES < "${DC_WORK}/COMP.CNT"
read -r TOTAL_SCRIPTS MISSING_SCRIPT_HEADERS < "${DC_WORK}/HDR.CNT"
read -r MISSING_SCHEMA_DOCS < "${DC_WORK}/SCH.CNT"
read -r MISSING_FUNC_DOCS < "${DC_WORK}/SH.CNT"
read -r MISSING_CMD_DOCS < "${DC_WORK}/CMD.CNT"
read -r MISSING_PS1_DOCS < "${DC_WORK}/PS1.CNT"

TOTAL_ITEMS=$((TOTAL_COMPS + TOTAL_SCRIPTS))
MISSING_ITEMS=$((MISSING_COMP_READMES + MISSING_SCRIPT_HEADERS))
DOCUMENTED_ITEMS=$((TOTAL_ITEMS - MISSING_ITEMS))
if [ "$TOTAL_ITEMS" -gt 0 ]; then
  COVERAGE_PCT=$((DOCUMENTED_ITEMS * 100 / TOTAL_ITEMS))
else
  COVERAGE_PCT=100
fi

printf '==> Documentation Coverage: %d%% (%d/%d documented: %d/%d component READMEs, %d/%d script headers)\n' "$COVERAGE_PCT" "$DOCUMENTED_ITEMS" "$TOTAL_ITEMS" "$((TOTAL_COMPS - MISSING_COMP_READMES))" "$TOTAL_COMPS" "$((TOTAL_SCRIPTS - MISSING_SCRIPT_HEADERS))" "$TOTAL_SCRIPTS"

if [ "$UPDATE_README" -eq 1 ]; then
  update_readme_shield "$README_FILE" "$COVERAGE_PCT"
fi

TOTAL_ERRORS=$((MISSING_COMP_READMES + MISSING_SCRIPT_HEADERS + MISSING_SCHEMA_DOCS + MISSING_FUNC_DOCS + MISSING_CMD_DOCS + MISSING_PS1_DOCS))

if [ "$TOTAL_ERRORS" -eq 0 ]; then
  printf '[PASS] 100%% Documentation Coverage Audit Passed!\n'
  exit 0
else
  printf '[ERROR] Found %d missing component READMEs, %d scripts missing header docs, %d schema files, %d shell scripts, %d batch files, and %d powershell scripts with missing or placeholder docs.\n' "$MISSING_COMP_READMES" "$MISSING_SCRIPT_HEADERS" "$MISSING_SCHEMA_DOCS" "$MISSING_FUNC_DOCS" "$MISSING_CMD_DOCS" "$MISSING_PS1_DOCS" >&2
  exit 1
fi
