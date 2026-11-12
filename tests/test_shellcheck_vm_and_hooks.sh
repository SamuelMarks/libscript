#!/bin/sh
# ## Overview
# End-to-end behavioral test suite for the ShellCheck native version manager (`_lib/toolchains/shellcheck`)
# and automatic pre-commit hook bootstrapping when `shellcheck` is nonexistent on `PATH`.
#
# ## Usage
# ./tests/test_shellcheck_vm_and_hooks.sh

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

cd "$LIBSCRIPT_ROOT_DIR"

FAILURES=0
CHECKS=0

# ## pass_check
# Records a passing test assertion.
pass_check() {
  CHECKS=$((CHECKS + 1))
  printf '[PASS] %s\n' "$1"
}

# ## fail_check
# Records a failing test assertion and increments FAILURES.
fail_check() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf '[FAIL] %s\n' "$1" >&2
}

# ## build_mock_shellcheck_archive
# Creates an upstream-layout shellcheck-v<ver>.tar.gz archive for deterministic offline testing.
build_mock_shellcheck_archive() {
  _ver="$1"
  _out_tgz="$2"
  _real_sc="${3:-}"
  _pkg_stage="${TEST_WS}/build_stage_${_ver}"
  rm -rf "$_pkg_stage"
  mkdir -p "$_pkg_stage/shellcheck-v${_ver}"

  if [ -n "$_real_sc" ] && [ -x "$_real_sc" ]; then
    cat <<EOF > "$_pkg_stage/shellcheck-v${_ver}/shellcheck"
#!/bin/sh
if [ "\${1:-}" = "--version" ]; then
  printf 'ShellCheck - shell script analysis tool\nversion: %s\n' "${_ver}"
  exit 0
fi
exec "${_real_sc}" "\$@"
EOF
  else
    cat <<EOF > "$_pkg_stage/shellcheck-v${_ver}/shellcheck"
#!/bin/sh
if [ "\${1:-}" = "--version" ]; then
  printf 'ShellCheck - shell script analysis tool\nversion: %s\n' "${_ver}"
  exit 0
fi
if [ "\${1:-}" = "--list-optional" ]; then
  printf 'name:    useless-use-of-cat\n'
  exit 0
fi
for _arg in "\$@"; do
  if [ -f "\$_arg" ]; then
    if grep -q 'SC_TRIGGER_ERROR' "\$_arg" 2>/dev/null || ! sh -n "\$_arg" 2>/dev/null; then
      printf 'In %s line 1: synthetic shellcheck violation\n' "\$_arg" >&2
      exit 1
    fi
  fi
done
exit 0
EOF
  fi

  chmod +x "$_pkg_stage/shellcheck-v${_ver}/shellcheck"
  printf 'GPL-3.0-or-later\n' > "$_pkg_stage/shellcheck-v${_ver}/LICENSE.txt"
  printf 'ShellCheck %s README\n' "$_ver" > "$_pkg_stage/shellcheck-v${_ver}/README.txt"
  tar -czf "$_out_tgz" -C "$_pkg_stage" "shellcheck-v${_ver}"
  rm -rf "$_pkg_stage"
}

# ## populate_restricted_bin_without_shellcheck
# Mirrors host PATH executables into a synthetic directory while strictly omitting shellcheck.
populate_restricted_bin_without_shellcheck() {
  _dest_bin="$1"
  mkdir -p "$_dest_bin"
  printf '%s\n' "$PATH" | tr ':' '\n' | while IFS= read -r _path_dir; do
    [ -n "$_path_dir" ] && [ -d "$_path_dir" ] || continue
    find "$_path_dir" -maxdepth 1 \( -type f -o -type l \) 2>/dev/null | while IFS= read -r _exe; do
      [ -n "$_exe" ] || continue
      _exe_name=$(basename "$_exe")
      [ "$_exe_name" = "shellcheck" ] && continue
      if [ -x "$_exe" ] && [ ! -e "$_dest_bin/$_exe_name" ]; then
        ln -sf "$_exe" "$_dest_bin/$_exe_name" 2>/dev/null || true
      fi
    done
  done
  rm -f "$_dest_bin/shellcheck"
}

TEST_WS=$(mktemp -d "${TMPDIR:-/tmp}/libscript_sc_vm_test.XXXXXX")
trap 'rm -rf "$TEST_WS" 2>/dev/null || true' EXIT INT TERM HUP

printf '=== 1. Auditing _lib/toolchains/shellcheck Standards & Parity ===\n'
if ./devtools/audit/audit_version_manager.sh _lib/toolchains/shellcheck >/dev/null 2>&1; then
  pass_check "_lib/toolchains/shellcheck satisfies Version Manager Contract audit"
else
  fail_check "_lib/toolchains/shellcheck failed Version Manager Contract audit"
fi

if ./devtools/audit/audit_schema_vars.sh >/dev/null 2>&1; then
  pass_check "_lib/toolchains/shellcheck satisfies Schema Variable Coverage audit"
else
  fail_check "_lib/toolchains/shellcheck failed Schema Variable Coverage audit"
fi

_missing_cmd=0
for _sh_f in $(find _lib/toolchains/shellcheck -maxdepth 1 -name '*.sh' | sort); do
  _cmd_f="${_sh_f%.sh}.cmd"
  if [ ! -f "$_cmd_f" ]; then
    fail_check "Missing Windows Batch companion: $_cmd_f"
    _missing_cmd=1
  fi
done
if [ "$_missing_cmd" -eq 0 ]; then
  pass_check "1:1 .sh / .cmd companion parity verified across _lib/toolchains/shellcheck"
fi

printf '=== 2. Testing Non-Invasive Isolation, Multi-Version Coexistence & Idempotency ===\n'
FAKE_HOME="${TEST_WS}/fake_home"
FAKE_LS_HOME="${TEST_WS}/ls_home"
UPSTREAM_DIR="${TEST_WS}/upstream"
DL_CACHE="${TEST_WS}/dl_cache"
mkdir -p "$FAKE_HOME" "$FAKE_LS_HOME" "$UPSTREAM_DIR" "$DL_CACHE"

printf '# untouched bashrc\n' > "$FAKE_HOME/.bashrc"
printf '# untouched profile\n' > "$FAKE_HOME/.profile"
printf '# untouched zshrc\n' > "$FAKE_HOME/.zshrc"

HOST_SC=$(command -v shellcheck 2>/dev/null || true)
build_mock_shellcheck_archive "0.10.0" "${UPSTREAM_DIR}/shellcheck-v0.10.0.tar.gz" "$HOST_SC"
build_mock_shellcheck_archive "0.11.0" "${UPSTREAM_DIR}/shellcheck-v0.11.0.tar.gz" "$HOST_SC"

mkdir -p "${DL_CACHE}/shellcheck"
cp -f "${UPSTREAM_DIR}/shellcheck-v0.10.0.tar.gz" "${DL_CACHE}/shellcheck/shellcheck-v0.10.0.tar.gz"
cp -f "${UPSTREAM_DIR}/shellcheck-v0.11.0.tar.gz" "${DL_CACHE}/shellcheck/shellcheck-v0.11.0.tar.gz"

(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  SHELLCHECK_DOWNLOAD_URL="https://example.invalid/shellcheck-v{VERSION}.tar.gz" \
  STACK="" \
  ./libscript.sh install shellcheck 0.11.0 >/dev/null
)

if [ -x "${FAKE_LS_HOME}/shellcheck/0.11.0/bin/shellcheck" ] && [ -f "${FAKE_LS_HOME}/shellcheck/0.11.0/LICENSE.txt" ]; then
  pass_check "Installed shellcheck 0.11.0 binary and LICENSE.txt into isolated LIBSCRIPT_HOME"
else
  fail_check "Failed to install shellcheck 0.11.0 into ${FAKE_LS_HOME}/shellcheck/0.11.0"
fi

IDEMP_OUT=$(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  SHELLCHECK_DOWNLOAD_URL="https://example.invalid/shellcheck-v{VERSION}.tar.gz" \
  STACK="" \
  ./libscript.sh install shellcheck 0.11.0 2>&1
)
if printf '%s\n' "$IDEMP_OUT" | grep -q "already installed"; then
  pass_check "Second install of shellcheck 0.11.0 exited idempotently ('already installed')"
else
  fail_check "Second install of shellcheck 0.11.0 did not hit idempotent early exit: $IDEMP_OUT"
fi

(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  SHELLCHECK_DOWNLOAD_URL="https://example.invalid/shellcheck-v{VERSION}.tar.gz" \
  STACK="" \
  ./libscript.sh install shellcheck 0.10.0 >/dev/null
)

OUT_010=$(LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" ./libscript.sh run shellcheck 0.10.0 --version 2>/dev/null || true)
OUT_011=$(LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" ./libscript.sh run shellcheck 0.11.0 --version 2>/dev/null || true)
if printf '%s\n' "$OUT_010" | grep -q "0.10.0" && printf '%s\n' "$OUT_011" | grep -q "0.11.0"; then
  pass_check "Side-by-side coexistence verified for shellcheck 0.10.0 and 0.11.0 via 'run'"
else
  fail_check "Side-by-side 'run' output mismatch: 0.10.0='$OUT_010', 0.11.0='$OUT_011'"
fi

WHICH_011=$(LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" ./libscript.sh which shellcheck 0.11.0 2>&1 || true)
if printf '%s\n' "$WHICH_011" | grep -q "${FAKE_LS_HOME}/shellcheck/0.11.0/bin/shellcheck"; then
  pass_check "'which shellcheck 0.11.0' resolved exact isolated binary path"
else
  fail_check "'which shellcheck 0.11.0' returned unexpected path: $WHICH_011"
fi

for _fmt in sh cmd ps1 fish json; do
  _env_out=$(LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" ./libscript.sh env shellcheck 0.11.0 "--format=${_fmt}" 2>/dev/null || true)
  if printf '%s\n' "$_env_out" | grep -q "0.11.0"; then
    pass_check "'env shellcheck 0.11.0 --format=${_fmt}' emitted isolated bin path"
  else
    fail_check "'env shellcheck 0.11.0 --format=${_fmt}' failed: $_env_out"
  fi
done

if [ "$(cat "$FAKE_HOME/.bashrc")" = "# untouched bashrc" ] && \
   [ "$(cat "$FAKE_HOME/.profile")" = "# untouched profile" ] && \
   [ "$(cat "$FAKE_HOME/.zshrc")" = "# untouched zshrc" ]; then
  pass_check "Zero global shell profile pollution (.bashrc, .profile, .zshrc untouched)"
else
  fail_check "Global shell profile files were modified!"
fi

LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK="" ./libscript.sh uninstall shellcheck 0.10.0 >/dev/null 2>&1
if [ ! -d "${FAKE_LS_HOME}/shellcheck/0.10.0" ] && [ -x "${FAKE_LS_HOME}/shellcheck/0.11.0/bin/shellcheck" ]; then
  pass_check "Uninstalling shellcheck 0.10.0 preserved 0.11.0 side-by-side installation"
else
  fail_check "Uninstall of 0.10.0 corrupted 0.11.0 or failed to remove 0.10.0"
fi

printf '=== 3. Testing Pre-Commit Hook Auto-Bootstrap When ShellCheck Is Nonexistent ===\n'
BIN_NO_SC="${TEST_WS}/bin_no_sc"
populate_restricted_bin_without_shellcheck "$BIN_NO_SC"

if PATH="$BIN_NO_SC" sh -c 'command -v shellcheck' >/dev/null 2>&1; then
  fail_check "Synthetic restricted PATH unexpectedly contained shellcheck"
else
  pass_check "Verified shellcheck is nonexistent on restricted PATH"
fi

HOOK_REPO="${TEST_WS}/hook_repo"
HOOK_LS_HOME="${TEST_WS}/hook_ls_home"
mkdir -p "$HOOK_REPO" "$HOOK_LS_HOME"
(
  cd "$HOOK_REPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "LibScript Test"
  cat << 'EOF' > valid_script.sh
#!/bin/sh
# ## Overview
# Valid POSIX shell script for pre-commit hook bootstrap testing.
#
# ## Usage
# ./valid_script.sh

set -feu
printf '%s\n' 'hello world'
EOF
  chmod +x valid_script.sh
  git add valid_script.sh
)

HOOK_RUN1=$(
  cd "$HOOK_REPO"
  unset SCRIPT_NAME || true
  PATH="$BIN_NO_SC" \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$HOOK_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  SHELLCHECK_VERSION="0.11.0" \
  SHELLCHECK_DOWNLOAD_URL="https://example.invalid/shellcheck-v{VERSION}.tar.gz" \
  STACK="" \
  sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" 2>&1
)

if printf '%s\n' "$HOOK_RUN1" | grep -q "\[BOOTSTRAP\] shellcheck not found on PATH" && \
   [ -x "${HOOK_LS_HOME}/shellcheck/0.11.0/bin/shellcheck" ]; then
  pass_check "Pre-commit hook automatically bootstrapped nonexistent shellcheck into LIBSCRIPT_HOME and passed valid.sh"
else
  fail_check "Pre-commit hook failed to auto-bootstrap nonexistent shellcheck: $HOOK_RUN1"
fi

HOOK_RUN2=$(
  cd "$HOOK_REPO"
  unset SCRIPT_NAME || true
  PATH="$BIN_NO_SC" \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$HOOK_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  SHELLCHECK_VERSION="0.11.0" \
  SHELLCHECK_DOWNLOAD_URL="https://example.invalid/shellcheck-v{VERSION}.tar.gz" \
  STACK="" \
  sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" 2>&1
)

if ! printf '%s\n' "$HOOK_RUN2" | grep -q "\[BOOTSTRAP\]" && \
   printf '%s\n' "$HOOK_RUN2" | grep -q "Running shellcheck..."; then
  pass_check "Second pre-commit hook run reused bootstrapped shellcheck idempotently without re-installing"
else
  fail_check "Second pre-commit hook run was not idempotent: $HOOK_RUN2"
fi

(
  cd "$HOOK_REPO"
  cat << 'EOF' > broken_script.sh
#!/bin/sh
# SC_TRIGGER_ERROR
echo $unquoted_var_error
if [ ]; then
EOF
  git add broken_script.sh
)

if (
  cd "$HOOK_REPO"
  unset SCRIPT_NAME || true
  PATH="$BIN_NO_SC" \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$HOOK_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  SHELLCHECK_VERSION="0.11.0" \
  STACK="" \
  sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" >/dev/null 2>&1
); then
  fail_check "Pre-commit hook should have failed on broken_script.sh via bootstrapped shellcheck"
else
  pass_check "Bootstrapped shellcheck in pre-commit hook caught broken_script.sh and exited non-zero"
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] ShellCheck VM & Hook Bootstrap Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '=== All %d ShellCheck VM & Pre-Commit Bootstrap Checks Passed! ===\n' "$CHECKS"
exit 0
