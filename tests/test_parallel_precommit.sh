#!/bin/sh
# ## Overview
# Hermetic unit and integration test suite for `engine/common/parallel.{sh,cmd}` and the
# concurrent `.githooks/pre-commit.{sh,cmd}` pipeline, verifying genuine parallel execution,
# `LIBSCRIPT_JOBS` overrides, whitespace-safe batching, MS-DOS (`IS_MSDOS=1` / `ls_wincmd`)
# graceful sequential fallback, zero non-POSIX flags, and 2x idempotency.
# ## Usage
# ./tests/test_parallel_precommit.sh
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

TP_WORK=$(libscript_make_tmpdir 'parallel')
trap 'rm -rf "$TP_WORK"' EXIT INT TERM HUP

CHECKS=0
FAILURES=0

# ## pass_check
# Records and prints a passing test assertion.
pass_check() {
  CHECKS=$((CHECKS + 1))
  printf '[PASS] %s\n' "$1"
}

# ## fail_check
# Records and prints a failing test assertion to stderr.
fail_check() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf '[FAIL] %s\n' "$1" >&2
}

printf '%s\n' '=== 1. Testing LIBSCRIPT_JOBS & CPU Core Auto-Detection ==='

_auto_j=$(unset LIBSCRIPT_JOBS IS_MSDOS LIBSCRIPT_DOS_83 || true; libscript_parallel_jobs)
case "$_auto_j" in
  ''|*[!0-9]*) fail_check "Auto-detected job count is non-numeric: $_auto_j" ;;
  *)
    if [ "$_auto_j" -ge 1 ] && [ "$_auto_j" -le 16 ]; then
      pass_check "Auto-detected job count resolved within 1..16 ($_auto_j)"
    else
      fail_check "Auto-detected job count out of expected 1..16 range: $_auto_j"
    fi
    ;;
esac

_ovr_j=$(LIBSCRIPT_JOBS=5 libscript_parallel_jobs)
if [ "$_ovr_j" = '5' ]; then
  pass_check 'LIBSCRIPT_JOBS=5 override honored'
else
  fail_check "Expected LIBSCRIPT_JOBS=5 -> 5, got $_ovr_j"
fi

_seq_j=$(LIBSCRIPT_JOBS=1 libscript_parallel_jobs)
if [ "$_seq_j" = '1' ]; then
  pass_check 'LIBSCRIPT_JOBS=1 sequential override honored'
else
  fail_check "Expected LIBSCRIPT_JOBS=1 -> 1, got $_seq_j"
fi

_bad_j=$(LIBSCRIPT_JOBS=invalid LIBSCRIPT_HW_CORES=3 libscript_parallel_jobs)
if [ "$_bad_j" = '3' ]; then
  pass_check 'Invalid LIBSCRIPT_JOBS fell back to LIBSCRIPT_HW_CORES=3'
else
  fail_check "Expected invalid LIBSCRIPT_JOBS fallback -> 3, got $_bad_j"
fi

printf '%s\n' '=== 2. Testing MS-DOS Graceful Sequential Fallback & 8.3 Temp Names ==='

_dos_j1=$(IS_MSDOS=1 LIBSCRIPT_JOBS=8 libscript_parallel_jobs)
_dos_j2=$(LIBSCRIPT_DOS_83=1 LIBSCRIPT_JOBS=8 libscript_parallel_jobs)
_dos_j3=$(UNAME='MS-DOS' LIBSCRIPT_JOBS=8 libscript_parallel_jobs)
_no_bg_j=$(LIBSCRIPT_BG_SUPPORTED=0 LIBSCRIPT_JOBS=8 libscript_parallel_jobs)
if [ "$_dos_j1" = '1' ] && [ "$_dos_j2" = '1' ] && [ "$_dos_j3" = '1' ] && [ "$_no_bg_j" = '1' ]; then
  pass_check 'MS-DOS (IS_MSDOS=1, LIBSCRIPT_DOS_83=1, UNAME=MS-DOS) and non-forking shells gracefully fall back to 1 worker'
else
  fail_check "MS-DOS fallback failed: $_dos_j1 / $_dos_j2 / $_dos_j3 / $_no_bg_j"
fi

_dos_td=$(TMPDIR="$TP_WORK" IS_MSDOS=1 libscript_make_tmpdir 'long_prefix')
_dos_bn=$(basename "$_dos_td")
case "$_dos_bn" in
  LSP*.TMP)
    pass_check "MS-DOS temp dir uses FAT16 8.3 short name ($_dos_bn)"
    ;;
  *)
    fail_check "MS-DOS temp dir violated 8.3 naming: $_dos_bn"
    ;;
esac
rm -rf "$_dos_td"

_cc=$(command -v cc 2>/dev/null || command -v clang 2>/dev/null || command -v gcc 2>/dev/null || true)
if [ -n "$_cc" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/ls_wincmd.c" ]; then
  _wincmd_bin="${TP_WORK}/ls_wincmd"
  if "$_cc" -O2 "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/ls_wincmd.c" -o "$_wincmd_bin" 2>/dev/null; then
    cat <<EOF_DOS_BAT | awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' > "${TP_WORK}/TEST_DOS.BAT"
@echo off
set "STACK="
set "IS_MSDOS=1"
set "LIBSCRIPT_JOBS=8"
set "LIBSCRIPT_ROOT_DIR=${LIBSCRIPT_ROOT_DIR}"
call "${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.cmd" :detect_jobs
echo JOBS=%LIBSCRIPT_RESOLVED_JOBS% PAR=%LIBSCRIPT_PARALLEL_SUPPORTED%
EOF_DOS_BAT
    _dos_bat_out=$(STACK="" IS_MSDOS=1 "$_wincmd_bin" "${TP_WORK}/TEST_DOS.BAT" 2>/dev/null || true)
    if printf '%s\n' "$_dos_bat_out" | grep -q 'JOBS=1 PAR=0'; then
      pass_check 'engine/common/parallel.cmd executed cleanly in ls_wincmd MS-DOS batch interpreter (JOBS=1 PAR=0)'
    else
      fail_check "ls_wincmd MS-DOS fallback output unexpected: $_dos_bat_out"
    fi
  fi
fi

printf '%s\n' '=== 3. Testing Genuine Concurrency, Failure Propagation & Whitespace Batching ==='

# shellcheck disable=SC2329
# ## _tp_sleep_item
# Sleeps briefly and writes an output marker file per item.
_tp_sleep_item() {
  sleep 1
  printf 'done:%s\n' "$1" > "${TP_WORK}/item_${1}.out"
}

_items="${TP_WORK}/ITEMS.TXT"
printf '%s\n' 'a' 'b' 'c' 'd' > "$_items"
_t0=$(date +%s)
LIBSCRIPT_JOBS=4 libscript_parallel_map "$_items" _tp_sleep_item 4
_t1=$(date +%s)
_elapsed=$((_t1 - _t0))
if [ -f "${TP_WORK}/item_a.out" ] && [ -f "${TP_WORK}/item_d.out" ] && [ "$_elapsed" -lt 4 ]; then
  pass_check "4x 1s tasks completed concurrently in ${_elapsed}s (< 4s sequential wall time)"
else
  fail_check "Parallel map failed or ran sequentially (elapsed=${_elapsed}s)"
fi

# shellcheck disable=SC2329
# ## _tp_fail_item
# Returns exit status 1 when item equals 'bad' to test error propagation.
_tp_fail_item() {
  if [ "$1" = 'bad' ]; then
    return 1
  fi
  return 0
}

printf '%s\n' 'ok1' 'bad' 'ok2' > "${TP_WORK}/FAIL_ITEMS.TXT"
if LIBSCRIPT_JOBS=3 libscript_parallel_map "${TP_WORK}/FAIL_ITEMS.TXT" _tp_fail_item 3; then
  fail_check 'libscript_parallel_map failed to propagate non-zero worker exit code'
else
  pass_check 'libscript_parallel_map propagated non-zero worker exit code accurately'
fi

if IS_MSDOS=1 libscript_parallel_map "${TP_WORK}/FAIL_ITEMS.TXT" _tp_fail_item; then
  fail_check 'Sequential MS-DOS fallback failed to propagate non-zero worker exit code'
else
  pass_check 'Sequential MS-DOS fallback propagated non-zero worker exit code accurately'
fi

# shellcheck disable=SC2329
# ## _tp_record_batch
# Appends argument count and exact arguments to BATCH_OUT.TXT.
_tp_record_batch() {
  printf 'argc=%d:%s\n' "$#" "$*" >> "${TP_WORK}/BATCH_OUT.TXT"
}

printf '%s\n' 'alpha one.txt' 'beta two.txt' 'gamma three.txt' > "${TP_WORK}/SPACE_LIST.TXT"
: > "${TP_WORK}/BATCH_OUT.TXT"
libscript_batch_exec "${TP_WORK}/SPACE_LIST.TXT" 2 _tp_record_batch
if grep -q '^argc=2:alpha one\.txt beta two\.txt$' "${TP_WORK}/BATCH_OUT.TXT" && \
   grep -q '^argc=1:gamma three\.txt$' "${TP_WORK}/BATCH_OUT.TXT"; then
  pass_check 'libscript_batch_exec preserved filenames with spaces across chunk boundaries'
else
  fail_check "libscript_batch_exec corrupted spaced filenames: $(cat "${TP_WORK}/BATCH_OUT.TXT")"
fi

printf '%s\n' '=== 4. Auditing Zero Non-POSIX Constructs in Hooks & Modified Audit Scripts ==='

_non_posix_hits=$(awk '/^[[:space:]]*#/ { next } /(xargs[[:space:]].*-[P0]|grep[[:space:]].*--include=)/ { print FILENAME ":" FNR ":" $0 }' \
  "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" \
  "${LIBSCRIPT_ROOT_DIR}/.pre-commit-config.yaml" \
  "${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_posix.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_tiers.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_version_manager.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_schema_vars.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_cmd.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/audit/doc_coverage.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/docs-gen/generate_markdown_docs.sh" \
  "${LIBSCRIPT_ROOT_DIR}/devtools/docs-gen/inject_markers.sh" 2>/dev/null || true)
if [ -z "$_non_posix_hits" ]; then
  pass_check 'Zero non-POSIX xargs -P, xargs -0, or grep --include flags across hooks and parallelized audits'
else
  fail_check "Non-POSIX flags detected: $_non_posix_hits"
fi

printf '%s\n' '=== 5. Testing 2x Idempotent Pre-Commit Execution (Parallel & MS-DOS Fallback) ==='

_mock_repo="${TP_WORK}/mock_repo"
mkdir -p "$_mock_repo"
(
  cd "$_mock_repo"
  git init -q
  git config user.email 'test@libscript.invalid'
  git config user.name 'LibScript Test'
  cp "${LIBSCRIPT_ROOT_DIR}/.gitattributes" .gitattributes
  cp "${LIBSCRIPT_ROOT_DIR}/.cspell.json" .cspell.json
  cat <<'EOF_SH' > sample.sh
#!/bin/sh
# ## Overview
# Sample valid POSIX script for pre-commit hook verification.
# ## Usage
# ./sample.sh
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=${SCRIPT_DIR}}"
printf '%s\n' 'ok'
EOF_SH
  cat <<'EOF_CMD' | awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' > sample.cmd
@echo off
:: # sample.cmd
:: ## Overview
:: Sample valid Windows Batch companion script for pre-commit verification.
:: ## Usage
:: sample.cmd
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 exit /b 0
)
set "STACK=%STACK%:!THIS_FILE!:"
echo ok
exit /b 0
EOF_CMD
  chmod +x sample.sh
  git add .gitattributes .cspell.json sample.sh sample.cmd
)

if (
  cd "$_mock_repo"
  LIBSCRIPT_OFFLINE=1 LIBSCRIPT_JOBS=4 STACK='' sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" >/dev/null 2>&1 && \
  LIBSCRIPT_OFFLINE=1 LIBSCRIPT_JOBS=4 STACK='' sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" >/dev/null 2>&1 && \
  LIBSCRIPT_OFFLINE=1 IS_MSDOS=1 STACK='' sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" >/dev/null 2>&1
); then
  pass_check '2x parallel pre-commit + 1x IS_MSDOS=1 fallback pre-commit runs succeeded idempotently'
else
  fail_check 'Pre-commit hook failed during 2x parallel / MS-DOS fallback verification'
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] Parallel Pre-Commit Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '=== All %d Parallel Pre-Commit & MS-DOS Fallback Checks Passed! ===\n' "$CHECKS"
exit 0
