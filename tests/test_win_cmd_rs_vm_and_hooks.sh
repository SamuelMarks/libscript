#!/bin/sh
# ## Overview
# End-to-end behavioral test suite for `_lib/toolchains/win-cmd-rs` and automatic pre-commit hook `wincheck` bootstrapping.
#
# ## Usage
# ./tests/test_win_cmd_rs_vm_and_hooks.sh

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

# ## detect_host_rust_target
# Resolves the host Rust target triple matching setup_generic.sh.
detect_host_rust_target() {
  _h_os=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf '%s\n' 'linux')
  _h_arch=$(uname -m 2>/dev/null | tr '[:upper:]' '[:lower:]' || printf '%s\n' 'x86_64')
  case "${_h_os}:${_h_arch}" in
    darwin*:arm64|darwin*:aarch64) printf '%s\n' 'aarch64-apple-darwin' ;;
    darwin*:x86_64|darwin*:amd64) printf '%s\n' 'x86_64-apple-darwin' ;;
    linux*:aarch64|linux*:arm64) printf '%s\n' 'aarch64-unknown-linux-gnu' ;;
    *) printf '%s\n' 'x86_64-unknown-linux-musl' ;;
  esac
}

# ## build_mock_win_cmd_rs_archive
# Creates an upstream-layout win-cmd-rs-v<ver>-<target>.tar.gz archive containing wincheck and wincmd.
build_mock_win_cmd_rs_archive() {
  _ver="$1"
  _target="$2"
  _out_tgz="$3"
  _real_wc="${4:-}"
  _real_wm="${5:-}"
  _stage_name="win-cmd-rs-v${_ver}-${_target}"
  _pkg_stage="${TEST_WS}/build_stage_${_ver}"
  rm -rf "$_pkg_stage"
  mkdir -p "$_pkg_stage/${_stage_name}"

  if [ -n "$_real_wc" ] && [ -x "$_real_wc" ]; then
    cat <<EOF > "$_pkg_stage/${_stage_name}/wincheck"
#!/bin/sh
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-V" ]; then
  printf 'wincheck %s\n' "${_ver}"
  exit 0
fi
exec "${_real_wc}" "\$@"
EOF
  else
    cat <<EOF > "$_pkg_stage/${_stage_name}/wincheck"
#!/bin/sh
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-V" ]; then
  printf 'wincheck %s\n' "${_ver}"
  exit 0
fi
for _arg in "\$@"; do
  if [ -f "\$_arg" ]; then
    if awk 'BEGIN{d=0} /\(/ {d++} /^[[:space:]]*::/ && d>0 {exit 0} /\)/ && d>0 {d--} END{exit 1}' "\$_arg" 2>/dev/null; then
      printf '%s:1:1: error[CMD1001]: :: label comment used inside a ( ... ) block.\n' "\$_arg" >&2
      exit 1
    fi
  fi
done
exit 0
EOF
  fi

  if [ -n "$_real_wm" ] && [ -x "$_real_wm" ]; then
    cat <<EOF > "$_pkg_stage/${_stage_name}/wincmd"
#!/bin/sh
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-V" ]; then
  printf 'wincmd %s\n' "${_ver}"
  exit 0
fi
exec "${_real_wm}" "\$@"
EOF
  else
    cat <<EOF > "$_pkg_stage/${_stage_name}/wincmd"
#!/bin/sh
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-V" ]; then
  printf 'wincmd %s\n' "${_ver}"
  exit 0
fi
printf '42\n'
exit 0
EOF
  fi

  chmod +x "$_pkg_stage/${_stage_name}/wincheck" "$_pkg_stage/${_stage_name}/wincmd"
  printf '# win-cmd-rs %s\n' "$_ver" > "$_pkg_stage/${_stage_name}/README.md"
  printf '# Usage\n' > "$_pkg_stage/${_stage_name}/USAGE.md"
  printf 'MIT\n' > "$_pkg_stage/${_stage_name}/LICENSE-MIT"
  printf 'Apache-2.0\n' > "$_pkg_stage/${_stage_name}/LICENSE-APACHE"
  tar -czf "$_out_tgz" -C "$_pkg_stage" "${_stage_name}"
  rm -rf "$_pkg_stage"
}

# ## build_mock_msdos_zip
# Creates a mock win-cmd-rs-v<ver>-i586-pc-msdosdjgpp.zip archive containing WINCHECK.EXE, WINCMD.EXE, and CWSDPMI.EXE.
build_mock_msdos_zip() {
  _ver="$1"
  _out_zip="$2"
  _stage_name="win-cmd-rs-v${_ver}-i586-pc-msdosdjgpp"
  _dos_stage="${TEST_WS}/dos_stage_${_ver}"
  rm -rf "$_dos_stage"
  mkdir -p "$_dos_stage/${_stage_name}"
  printf 'MZ-MOCK-WINCHECK\n' > "$_dos_stage/${_stage_name}/WINCHECK.EXE"
  printf 'MZ-MOCK-WINCMD\n' > "$_dos_stage/${_stage_name}/WINCMD.EXE"
  printf 'MZ-MOCK-CWSDPMI\n' > "$_dos_stage/${_stage_name}/CWSDPMI.EXE"
  printf 'MIT\n' > "$_dos_stage/${_stage_name}/LICENSE-MIT"
  if command -v zip >/dev/null 2>&1; then
    (cd "$_dos_stage" && zip -qr "$_out_zip" "${_stage_name}")
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import os, sys, zipfile
src, stage, out = sys.argv[1], sys.argv[2], sys.argv[3]
with zipfile.ZipFile(out, "w") as zf:
    for root_d, _, files in os.walk(os.path.join(src, stage)):
        for fn in files:
            zf.write(os.path.join(root_d, fn), stage + "/" + fn)
' "$_dos_stage" "$_stage_name" "$_out_zip"
  else
    tar -cf "$_out_zip" -C "$_dos_stage" "${_stage_name}"
  fi
  rm -rf "$_dos_stage"
}

# ## populate_restricted_bin_without_wincheck
# Mirrors host PATH executables into a synthetic directory while strictly omitting wincheck and wincmd.
populate_restricted_bin_without_wincheck() {
  _dest_bin="$1"
  mkdir -p "$_dest_bin"
  _rev_dirs=''
  _old_ifs="$IFS"
  IFS=':'
  for _path_dir in $PATH; do
    [ -n "$_path_dir" ] && [ -d "$_path_dir" ] || continue
    _rev_dirs="${_path_dir}:${_rev_dirs}"
  done
  for _extra_dir in "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/bin" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/shellcheck/default/bin"; do
    if [ -d "$_extra_dir" ]; then
      _rev_dirs="${_extra_dir}:${_rev_dirs}"
    fi
  done
  set +f
  for _path_dir in $_rev_dirs; do
    [ -n "$_path_dir" ] && [ -d "$_path_dir" ] || continue
    ln -sf "$_path_dir"/* "$_dest_bin/" 2>/dev/null || true
  done
  set -f
  IFS="$_old_ifs"
  rm -f "$_dest_bin/wincheck" "$_dest_bin/wincmd"
}

TEST_WS=$(mktemp -d "${TMPDIR:-/tmp}/libscript_wcr_vm_test.XXXXXX")
trap 'rm -rf "$TEST_WS" 2>/dev/null || true' EXIT INT TERM HUP

printf '%s\n' '=== 1. Auditing _lib/toolchains/win-cmd-rs Standards & Companion Parity ==='
if "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_version_manager.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs" >/dev/null 2>&1; then
  pass_check '_lib/toolchains/win-cmd-rs satisfies Version Manager Contract audit'
else
  fail_check '_lib/toolchains/win-cmd-rs failed Version Manager Contract audit'
fi

if "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_schema_vars.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs" >/dev/null 2>&1; then
  pass_check '_lib/toolchains/win-cmd-rs satisfies Schema Variable Coverage audit'
else
  fail_check '_lib/toolchains/win-cmd-rs failed Schema Variable Coverage audit'
fi

_missing_cmd=0
for _sh_f in $(find "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs" -maxdepth 1 -name '*.sh' | sort); do
  _cmd_f="${_sh_f%.sh}.cmd"
  if [ ! -f "$_cmd_f" ]; then
    fail_check "Missing Windows Batch companion: $_cmd_f"
    _missing_cmd=1
  fi
done
if [ "$_missing_cmd" -eq 0 ]; then
  pass_check '1:1 .sh / .cmd companion parity verified across _lib/toolchains/win-cmd-rs'
fi

printf '%s\n' '=== 2. Testing Offline Multi-Version Coexistence, O(1) Switching & 2x Idempotency ==='
FAKE_HOME="${TEST_WS}/fake_home"
FAKE_LS_HOME="${TEST_WS}/ls_home"
DL_CACHE="${TEST_WS}/dl_cache"
mkdir -p "$FAKE_HOME" "$FAKE_LS_HOME" "${DL_CACHE}/win-cmd-rs"

printf '%s\n' '# untouched bashrc' > "$FAKE_HOME/.bashrc"
printf '%s\n' '# untouched profile' > "$FAKE_HOME/.profile"
printf '%s\n' '# untouched zshrc' > "$FAKE_HOME/.zshrc"

HOST_TARGET=$(detect_host_rust_target)
if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh" ]; then
  _t_saved_this="$THIS_FILE"
  _t_saved_dir="$SCRIPT_DIR"
  _t_saved_stack="$STACK"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
  unset SCRIPT_NAME || true
  THIS_FILE="$_t_saved_this"
  SCRIPT_DIR="$_t_saved_dir"
  STACK="$_t_saved_stack"
  export STACK
fi
HOST_WC=$(command -v wincheck 2>/dev/null || true)
HOST_WM=$(command -v wincmd 2>/dev/null || true)

build_mock_win_cmd_rs_archive '0.0.1' "$HOST_TARGET" "${DL_CACHE}/win-cmd-rs/win-cmd-rs-v0.0.1-${HOST_TARGET}.tar.gz" "$HOST_WC" "$HOST_WM"
build_mock_win_cmd_rs_archive '0.0.2' "$HOST_TARGET" "${DL_CACHE}/win-cmd-rs/win-cmd-rs-v0.0.2-${HOST_TARGET}.tar.gz" "$HOST_WC" "$HOST_WM"

MOCK_URL_TPL='https://example.invalid/win-cmd-rs-v{VERSION}-{RUST_TARGET}.{EXT}'

(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" download win-cmd-rs 0.0.1 >/dev/null
)
pass_check 'Offline download verb succeeded idempotently with pre-cached archive'

(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs 0.0.1 >/dev/null
)

if [ -x "${FAKE_LS_HOME}/win-cmd-rs/0.0.1/bin/wincheck" ] && \
   [ -x "${FAKE_LS_HOME}/win-cmd-rs/0.0.1/bin/wincmd" ] && \
   [ -x "${FAKE_LS_HOME}/bin/wincheck" ] && \
   [ -x "${FAKE_LS_HOME}/bin/wincmd" ]; then
  pass_check 'Installed win-cmd-rs 0.0.1 (wincheck + wincmd) and synced active LIBSCRIPT_HOME/bin'
else
  fail_check "Failed to stage both wincheck and wincmd in ${FAKE_LS_HOME}/win-cmd-rs/0.0.1/bin"
fi

IDEMP_OUT=$(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs 0.0.1 2>&1
)
if printf '%s\n' "$IDEMP_OUT" | grep -q 'already installed'; then
  pass_check "Second install of win-cmd-rs 0.0.1 exited idempotently ('already installed')"
else
  fail_check "Second install of win-cmd-rs 0.0.1 did not hit idempotent early exit: $IDEMP_OUT"
fi

(
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$FAKE_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs 0.0.2 >/dev/null
)

ACTIVE_VER=$("${FAKE_LS_HOME}/bin/wincheck" --version 2>/dev/null || true)
if printf '%s\n' "$ACTIVE_VER" | grep -q '0.0.2'; then
  pass_check 'Installing win-cmd-rs 0.0.2 updated active LIBSCRIPT_HOME/bin/wincheck to 0.0.2'
else
  fail_check "Expected active wincheck 0.0.2, got: $ACTIVE_VER"
fi

LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" use win-cmd-rs 0.0.1 >/dev/null
SWITCHED_VER=$("${FAKE_LS_HOME}/bin/wincheck" --version 2>/dev/null || true)
if printf '%s\n' "$SWITCHED_VER" | grep -q '0.0.1'; then
  pass_check "O(1) 'use win-cmd-rs 0.0.1' switched active LIBSCRIPT_HOME/bin/{wincheck,wincmd} to 0.0.1"
else
  fail_check "Expected active wincheck 0.0.1 after 'use', got: $SWITCHED_VER"
fi

LS_OUT=$(LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls win-cmd-rs 2>/dev/null || true)
if printf '%s\n' "$LS_OUT" | grep -q '0.0.1' && printf '%s\n' "$LS_OUT" | grep -q '0.0.2'; then
  pass_check "'ls win-cmd-rs' listed both installed versions (0.0.1 and 0.0.2)"
else
  fail_check "'ls win-cmd-rs' output missing versions: $LS_OUT"
fi

if LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" test win-cmd-rs >/dev/null 2>&1; then
  pass_check "'test win-cmd-rs' smoke test passed"
else
  fail_check "'test win-cmd-rs' smoke test failed"
fi

LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" uninstall win-cmd-rs 0.0.2 >/dev/null 2>&1
LIBSCRIPT_HOME="$FAKE_LS_HOME" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" uninstall win-cmd-rs 0.0.2 >/dev/null 2>&1
if [ ! -d "${FAKE_LS_HOME}/win-cmd-rs/0.0.2" ] && [ -x "${FAKE_LS_HOME}/win-cmd-rs/0.0.1/bin/wincheck" ]; then
  pass_check '2x consecutive uninstall of win-cmd-rs 0.0.2 succeeded idempotently while preserving 0.0.1'
else
  fail_check '2x uninstall of 0.0.2 failed or corrupted 0.0.1'
fi

if [ "$(cat "$FAKE_HOME/.bashrc")" = '# untouched bashrc' ] && \
   [ "$(cat "$FAKE_HOME/.profile")" = '# untouched profile' ] && \
   [ "$(cat "$FAKE_HOME/.zshrc")" = '# untouched zshrc' ]; then
  pass_check 'Zero global shell profile pollution (.bashrc, .profile, .zshrc untouched)'
else
  fail_check 'Global shell profile files were modified!'
fi

printf '%s\n' '=== 3. Testing MS-DOS (LIBSCRIPT_TARGET_OS=msdos) DJGPP Cross-Staging ==='
DOS_LS_HOME="${TEST_WS}/dos_ls_home"
mkdir -p "$DOS_LS_HOME"
build_mock_msdos_zip '0.0.1' "${DL_CACHE}/win-cmd-rs/win-cmd-rs-v0.0.1-i586-pc-msdosdjgpp.zip"

if (
  unset SCRIPT_NAME || true
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$DOS_LS_HOME" \
  LIBSCRIPT_TARGET_OS='msdos' \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs 0.0.1 >/dev/null 2>&1
); then
  _dos_wc=$(find "$DOS_LS_HOME" -name 'WINCHECK.EXE' 2>/dev/null | head -n 1 || true)
  _dos_wm=$(find "$DOS_LS_HOME" -name 'WINCMD.EXE' 2>/dev/null | head -n 1 || true)
  _dos_dpmi=$(find "$DOS_LS_HOME" -name 'CWSDPMI.EXE' 2>/dev/null | head -n 1 || true)
  if [ -n "$_dos_wc" ] && [ -n "$_dos_wm" ] && [ -n "$_dos_dpmi" ]; then
    pass_check 'MS-DOS cross-staging installed WINCHECK.EXE, WINCMD.EXE, and CWSDPMI.EXE'
  else
    fail_check "MS-DOS cross-staging missing expected DJGPP binaries in $DOS_LS_HOME"
  fi
else
  fail_check 'MS-DOS (LIBSCRIPT_TARGET_OS=msdos) install win-cmd-rs 0.0.1 failed'
fi

printf '%s\n' '=== 4. Testing Pre-Commit Hook Auto-Bootstrap & Defect Gate When WinCheck Is Nonexistent ==='
BIN_NO_WC="${TEST_WS}/bin_no_wc"
populate_restricted_bin_without_wincheck "$BIN_NO_WC"

if PATH="$BIN_NO_WC" sh -c 'command -v wincheck' >/dev/null 2>&1; then
  fail_check 'Synthetic restricted PATH unexpectedly contained wincheck'
else
  pass_check 'Verified wincheck is nonexistent on restricted PATH'
fi

HOOK_REPO="${TEST_WS}/hook_repo"
HOOK_LS_HOME="${TEST_WS}/hook_ls_home"
mkdir -p "$HOOK_REPO" "$HOOK_LS_HOME"
(
  cd "$HOOK_REPO"
  git init -q
  git config user.email 'test@example.com'
  git config user.name 'LibScript Test'
  cp "${LIBSCRIPT_ROOT_DIR}/.cspell.json" .cspell.json
  printf '@echo off\r\n:: # valid.cmd\r\n:: ## Overview\r\n:: Valid batch script.\r\n:: ## Usage\r\n:: valid.cmd\r\nsetlocal EnableDelayedExpansion\r\necho hello\r\nexit /b 0\r\n' > valid.cmd
  git add valid.cmd
)

HOOK_RUN1_RC=0
HOOK_RUN1=$(
  cd "$HOOK_REPO"
  unset SCRIPT_NAME || true
  PATH="$BIN_NO_WC" \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$HOOK_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  WIN_CMD_RS_VERSION='0.0.1' \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" 2>&1
) || HOOK_RUN1_RC=$?

if [ "$HOOK_RUN1_RC" -eq 0 ] && \
   printf '%s\n' "$HOOK_RUN1" | grep -q '\[BOOTSTRAP\] wincheck not found on PATH' && \
   [ -x "${HOOK_LS_HOME}/win-cmd-rs/0.0.1/bin/wincheck" ]; then
  pass_check 'Pre-commit hook automatically bootstrapped nonexistent wincheck into LIBSCRIPT_HOME and passed valid.cmd'
else
  fail_check "Pre-commit hook failed (rc=${HOOK_RUN1_RC}) to auto-bootstrap nonexistent wincheck: $HOOK_RUN1"
fi

HOOK_RUN2=$(
  cd "$HOOK_REPO"
  unset SCRIPT_NAME || true
  PATH="$BIN_NO_WC" \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$HOOK_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  WIN_CMD_RS_VERSION='0.0.1' \
  WIN_CMD_RS_DOWNLOAD_URL="$MOCK_URL_TPL" \
  STACK='' \
  sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" 2>&1
)

if ! printf '%s\n' "$HOOK_RUN2" | grep -q '\[BOOTSTRAP\]' && \
   printf '%s\n' "$HOOK_RUN2" | grep -q 'Running wincheck...'; then
  pass_check 'Second pre-commit hook run reused bootstrapped wincheck idempotently without re-installing'
else
  fail_check "Second pre-commit hook run was not idempotent: $HOOK_RUN2"
fi

(
  cd "$HOOK_REPO"
  printf '@echo off\r\n:: # broken.cmd\r\n:: ## Overview\r\n:: Broken batch script.\r\n:: ## Usage\r\n:: broken.cmd\r\nif "1"=="1" (\r\n    :: CMD1001 double-colon inside parenthesized block\r\n    echo broken\r\n)\r\n' > broken.cmd
  git add broken.cmd
)

if (
  cd "$HOOK_REPO"
  unset SCRIPT_NAME || true
  PATH="$BIN_NO_WC" \
  HOME="$FAKE_HOME" \
  LIBSCRIPT_HOME="$HOOK_LS_HOME" \
  DOWNLOAD_DIR="$DL_CACHE" \
  LIBSCRIPT_CACHE_DIR="$DL_CACHE" \
  LIBSCRIPT_OFFLINE=1 \
  WIN_CMD_RS_VERSION='0.0.1' \
  STACK='' \
  sh "${LIBSCRIPT_ROOT_DIR}/.githooks/pre-commit.sh" >/dev/null 2>&1
); then
  fail_check 'Pre-commit hook should have failed on broken.cmd (CMD1001) via bootstrapped wincheck'
else
  pass_check 'Bootstrapped wincheck in pre-commit hook caught broken.cmd (CMD1001) and exited non-zero'
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] win-cmd-rs VM & Hook Bootstrap Suite failed (%d/%d checks failed)\n' "$FAILURES" "$CHECKS" >&2
  exit 1
fi

printf '=== All %d win-cmd-rs VM & Pre-Commit Bootstrap Checks Passed! ===\n' "$CHECKS"
exit 0
