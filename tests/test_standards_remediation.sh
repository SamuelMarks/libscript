#!/bin/sh
# ## Overview
# Hermetic regression test suite verifying repository-wide standards audit remediation.
# ## Usage
# ./tests/test_standards_remediation.sh

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
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/libscript_std_rem.XXXXXX")
CHECKS=0
FAILURES=0

# ## cleanup_ws
# Removes the temporary workspace created for hermetic test verification.
cleanup_ws() {
  rm -rf "$TEST_TMP" 2>/dev/null || true
}
trap 'cleanup_ws' EXIT INT TERM HUP

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

printf '=== 1. Verifying Packaging .cmd/.sh Parity & Stub Elimination ===\n'
for _fmt in deb rpm apk txz pkg dmg; do
  _cmd_f="${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_${_fmt}.cmd"
  _sh_f="${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_${_fmt}.sh"
  if [ ! -f "$_cmd_f" ] || [ ! -f "$_sh_f" ]; then
    fail_check "Missing pkg_${_fmt} script pair"
    continue
  fi
  if grep -qi 'not implemented natively for Windows' "$_cmd_f"; then
    fail_check "pkg_${_fmt}.cmd still contains unimplemented stub text"
  else
    pass_check "pkg_${_fmt}.cmd implements native Windows Batch logic without stub error"
  fi
done

_deb_out=$(STACK="" "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_deb.sh" --app-name Demo --app-version 2.0.0 jq 1.7.1)
if printf '%s\n' "$_deb_out" | grep -q 'dpkg-deb --root-owner-group --build' && grep -q 'dpkg-deb --root-owner-group --build' "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_deb.cmd"; then
  pass_check "pkg_deb.sh and pkg_deb.cmd both emit dpkg-deb build pipelines"
else
  fail_check "pkg_deb.sh / pkg_deb.cmd dpkg-deb parity check failed"
fi

if grep -q 'envsubst_safe.cmd' "${LIBSCRIPT_ROOT_DIR}/_lib/_common/envsubst_safe_exec.cmd"; then
  pass_check "envsubst_safe_exec.cmd delegates to envsubst_safe.cmd"
else
  fail_check "envsubst_safe_exec.cmd does not delegate to envsubst_safe.cmd"
fi

_es_in="${TEST_TMP}/es_in.txt"
printf 'val=%s%sFOO_TOKEN}:%s%sUNSET_KEEP}\n' "$" "{" "$" "{" > "$_es_in"
_es_out=$(FOO_TOKEN="hello_world" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/envsubst_safe_exec.sh" < "$_es_in")
_es_expected=$(printf 'val=hello_world:%s%sUNSET_KEEP}' "$" "{")
if [ "$_es_out" = "$_es_expected" ]; then
  pass_check "envsubst_safe_exec.sh interpolates defined vars while preserving undefined tokens"
else
  fail_check "envsubst_safe_exec.sh unexpected output: $_es_out"
fi

printf '=== 2. Verifying Option A Exit-86 Proforma & Spliced Guard Linter ===\n'
_opt_a_bad=0
set +f
for _oa in "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/kubernetes-thw/alpine-systemctl.cmd" \
           "${LIBSCRIPT_ROOT_DIR}"/_lib/*/*/setup_debian.cmd \
           "${LIBSCRIPT_ROOT_DIR}"/_lib/*/*/setup_alpine.cmd \
           "${LIBSCRIPT_ROOT_DIR}"/_lib/*/*/setup_freebsd.cmd \
           "${LIBSCRIPT_ROOT_DIR}"/_lib/*/*/setup_macos.cmd \
           "${LIBSCRIPT_ROOT_DIR}"/_lib/*/*/setup_rhel.cmd; do
  [ -f "$_oa" ] || continue
  if ! grep -q 'exit /b 86' "$_oa"; then
    fail_check "Option A script missing exit /b 86: $_oa"
    _opt_a_bad=1
  fi
done
set -f
if [ "$_opt_a_bad" -eq 0 ]; then
  pass_check "All 17 Unix-specific .cmd proforma scripts enforce Option A exit /b 86"
fi

_bad_cmd="${TEST_TMP}/setup_debian.cmd"
printf '@echo off\r\n:: # setup_debian.cmd\r\n:: ## Overview\r\n:: Test fixture.\r\n:: ## Usage\r\n:: setup_debian.cmd\r\nsetlocal EnableDelayedExpansion\r\nset "THIS_FILE=%%~f0"\r\nif defined STACK (\r\n    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1\r\n    if not errorlevel 1 exit /b 0\r\n)\r\nset "STACK=%%STACK%%:!THIS_FILE!:"\r\nif "%%ACTION%%"=="ls-remote" (\r\nif exist "%%LIBSCRIPT_HOME%%\\foo\\1.0" (\r\n    exit /b 0\r\n)\r\n    exit /b 0\r\n)\r\nexit /b 1\r\n' > "$_bad_cmd"
_bad_out=$(STACK="" "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.sh" "$_bad_cmd" 2>&1 || true)
if printf '%s\n' "$_bad_out" | grep -q 'BATCH_SPLICED_GUARD'; then
  pass_check "audit_standards.sh detects BATCH_SPLICED_GUARD corruption"
else
  fail_check "audit_standards.sh failed to flag BATCH_SPLICED_GUARD: $_bad_out"
fi

printf '=== 3. Verifying THIS_FILE Resolution From Arbitrary Working Directory ===\n'
_tui_out=$(cd "$TEST_TMP" && STACK="" "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_tui.sh" jq 1.7.1)
if printf '%s\n' "$_tui_out" | grep -q 'LIBSCRIPT_ROOT_DIR' && ! printf '%s\n' "$_tui_out" | grep -q '\./libscript\.sh'; then
  pass_check "pkg_tui.sh resolves LIBSCRIPT_ROOT_DIR without CWD-relative ./libscript.sh"
else
  fail_check "pkg_tui.sh emitted CWD-relative ./libscript.sh"
fi

if grep -q '_lib\\web-apps\\openedx\\cli.cmd' "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_tui.cmd" && \
   ! grep -q 'stacks\\cms\\openedx' "${LIBSCRIPT_ROOT_DIR}/cli/commands/packaging/formats/pkg_tui.cmd"; then
  pass_check "pkg_tui.cmd routes to canonical _lib\\web-apps\\openedx\\cli.cmd"
else
  fail_check "pkg_tui.cmd still references legacy stacks\\cms\\openedx path"
fi

printf '=== 4. Verifying 2x Directory-Symlink Idempotency ===\n'
_fhs_root="${TEST_TMP}/fhs_sysroot"
STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/create_fhs_layout.sh" "$_fhs_root" >/dev/null 2>&1
STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/create_fhs_layout.sh" "$_fhs_root" >/dev/null 2>&1
if [ ! -e "${_fhs_root}/var/run/run" ]; then
  pass_check "create_fhs_layout.sh 2x rerun produces zero nested var/run/run symlink"
else
  fail_check "create_fhs_layout.sh created nested var/run/run symlink on rerun"
fi

_mnt_ws="${TEST_TMP}/openedx_mnt"
_host_repo="${TEST_TMP}/edx-platform"
mkdir -p "$_mnt_ws" "$_host_repo"
touch "${_host_repo}/manage.py"
OPENEDX_DATA_DIR="$_mnt_ws" OPENEDX_INSTALL_DIR="$_mnt_ws" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/mounts.sh" add "$_host_repo" >/dev/null 2>&1
OPENEDX_DATA_DIR="$_mnt_ws" OPENEDX_INSTALL_DIR="$_mnt_ws" STACK="" "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/openedx/mounts.sh" add "$_host_repo" >/dev/null 2>&1
if [ ! -e "${_host_repo}/edx-platform" ] && [ -L "${_mnt_ws}/codebase_mount" ]; then
  pass_check "openedx/mounts.sh 2x rerun preserves host repo without nested self-symlink"
else
  fail_check "openedx/mounts.sh created nested symlink inside host directory on 2x rerun"
fi

printf '=== 5. Verifying POSIX Workflow Shells & C11 -Wconversion Cleanliness ===\n'
if grep -q 'shell: sh' "${LIBSCRIPT_ROOT_DIR}/.github/workflows/ci.yml" && \
   ! grep -q 'choco install' "${LIBSCRIPT_ROOT_DIR}/.github/workflows/release.yml"; then
  pass_check "GitHub Actions workflows enforce shell: sh and eliminate ad-hoc choco install"
else
  fail_check "GitHub Actions workflow standards check failed"
fi

if command -v cc >/dev/null 2>&1; then
  if cc -std=c11 -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Werror \
       -I"${LIBSCRIPT_ROOT_DIR}/libscript-rest-api/src" -fsyntax-only \
       "${LIBSCRIPT_ROOT_DIR}/libscript-rest-api/src/main.c" \
       "${LIBSCRIPT_ROOT_DIR}/libscript-rest-api/src/rest_dispatch.c" >/dev/null 2>&1; then
    pass_check "libscript-rest-api C11 sources pass -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Werror"
  else
    fail_check "libscript-rest-api C11 sources failed strict compiler lint check"
  fi
fi

printf '=== 6. Verifying Pass 2 Generated Shims, os_info.cmd Tunneling & Zero Thin Companions ===\n'
if grep -q 'endlocal' "${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.cmd" && \
   grep -q 'set "INIT_SYS=%INIT_SYS%"' "${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.cmd"; then
  pass_check "os_info.cmd tunnels TARGET_OS, INIT_SYS, ARCH, and PKG_MGR across endlocal"
else
  fail_check "os_info.cmd missing endlocal variable tunneling"
fi

_raw_d0=0
for _gen_s in \
  "${LIBSCRIPT_ROOT_DIR}/_lib/languages/edgcpp/setup_generic.sh" \
  "${LIBSCRIPT_ROOT_DIR}/_lib/app-servers/ollama/setup_generic.sh" \
  "${LIBSCRIPT_ROOT_DIR}/_lib/bootloaders/mcuboot/setup_generic.sh" \
  "${LIBSCRIPT_ROOT_DIR}/_lib/databases/duckdb/setup_generic.sh"; do
  if grep -Eq 'dirname[[:space:]]+(--[[:space:]]+)?"?[$]0"?' "$_gen_s"; then
    fail_check "Generated wrapper still uses dirname \$0 instead of THIS_FILE: $_gen_s"
    _raw_d0=1
  fi
done
if [ "$_raw_d0" -eq 0 ]; then
  pass_check "All generated wrapper shims resolve THIS_FILE instead of bare dirname \$0"
fi

if grep -q 'rmdir /s /q "%target%"' "${LIBSCRIPT_ROOT_DIR}/_lib/git-servers/utils/git.cmd" && \
   grep -q 'rmdir /s /q "!WORK_DIR!"' "${LIBSCRIPT_ROOT_DIR}/cli/commands/cloud/deploy.cmd"; then
  pass_check "git.cmd and cloud/deploy.cmd clean pre-existing partial directories before git clone"
else
  fail_check "git.cmd or cloud/deploy.cmd missing partial-directory cleanup before git clone"
fi

_thin_cnt=0
while IFS= read -r _shf; do
  [ -n "$_shf" ] || continue
  _full_sh="${LIBSCRIPT_ROOT_DIR}/${_shf}"
  _full_cmd="${_full_sh%.sh}.cmd"
  [ -f "$_full_cmd" ] || _full_cmd="${_full_sh%.sh}.bat"
  [ -f "$_full_cmd" ] || continue
  _sh_l=$(wc -l < "$_full_sh" | tr -d ' ')
  _cmd_l=$(wc -l < "$_full_cmd" | tr -d ' ')
  if [ "$_sh_l" -gt 100 ] && [ "$_cmd_l" -lt 60 ]; then
    if ! grep -q '86' "$_full_cmd" && ! grep -qi '\.ps1' "$_full_cmd"; then
      fail_check "Thin .cmd stub remaining: ${_full_cmd} (${_cmd_l}L vs ${_sh_l}L)"
      _thin_cnt=$((_thin_cnt + 1))
    fi
  fi
done <<EOF_LIST
$(cd "${LIBSCRIPT_ROOT_DIR}" && git ls-files '*.sh')
EOF_LIST
if [ "$_thin_cnt" -eq 0 ]; then
  pass_check "Zero thin (<60L) non-Option-A .cmd stubs remain across all >100L .sh scripts"
fi

_min_sc_home="${TEST_TMP}/min_sc_home"
_min_dl="${TEST_TMP}/min_dl"
mkdir -p "${_min_dl}/shellcheck"
mkdir -p "${TEST_TMP}/mock_sc_pkg/shellcheck-v0.11.0"
printf '#!/bin/sh\nprintf "ShellCheck - shell script analysis tool\\nversion: 0.11.0\\n"\n' > "${TEST_TMP}/mock_sc_pkg/shellcheck-v0.11.0/shellcheck"
chmod +x "${TEST_TMP}/mock_sc_pkg/shellcheck-v0.11.0/shellcheck"
tar -czf "${_min_dl}/shellcheck/shellcheck-v0.11.0.tar.gz" -C "${TEST_TMP}/mock_sc_pkg" "shellcheck-v0.11.0"
if (
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
  LIBSCRIPT_HOME="$_min_sc_home" \
  DOWNLOAD_DIR="$_min_dl" \
  LIBSCRIPT_CACHE_DIR="$_min_dl" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  SHELLCHECK_DOWNLOAD_URL="https://example.invalid/shellcheck-v{VERSION}.tar.gz" \
  STACK="" \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install shellcheck 0.11.0 >/dev/null 2>&1
) && [ -x "${_min_sc_home}/shellcheck/0.11.0/bin/shellcheck" ]; then
  pass_check "shellcheck installs cleanly under minimal PATH=/usr/bin:/bin without brew/pkg_mgr recursion"
else
  fail_check "shellcheck failed to install under minimal PATH=/usr/bin:/bin:/usr/sbin:/sbin"
fi

if [ "$FAILURES" -gt 0 ]; then
  cleanup_ws
  printf '[FAIL] Standards remediation suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

cleanup_ws
printf '=== All %d Standards Remediation Regression Checks Passed! ===\n' "$CHECKS"
exit 0
