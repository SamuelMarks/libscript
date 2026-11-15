#!/bin/sh
# ## Overview
# Integration tests verifying Pillar 1 (`VM-01`..`VM-15`) version-manager isolation, `O(1)` bin farm, and `.libscript-version`.
#
# ## Usage
# ./tests/test_vm_replacements.sh

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/os_info.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

TEST_TMP=$(mktemp -d)
export LIBSCRIPT_HOME="${TEST_TMP}/home"
export DOWNLOAD_DIR="${TEST_TMP}/downloads"
export LIBSCRIPT_OFFLINE=1

# ## fail_test
# Logs a test failure message, cleans up temporary directory, and exits non-zero.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  rm -rf "${TEST_TMP}"
  exit 1
}

# ## make_mock_rust_archive
# Builds a synthetic standalone Rust tarball for offline version-manager testing.
make_mock_rust_archive() {
  _v="$1"
  _stage="${TEST_TMP}/stage_rust_${_v}"
  mkdir -p "${_stage}/rust-${_v}/bin" "${DOWNLOAD_DIR}/rust"
  cat > "${_stage}/rust-${_v}/bin/rustc" << EOF
#!/bin/sh
printf 'rustc %s (libscript-isolated)\n' "${_v}"
EOF
  cat > "${_stage}/rust-${_v}/bin/cargo" << EOF
#!/bin/sh
printf 'cargo %s\n' "${_v}"
EOF
  chmod 755 "${_stage}/rust-${_v}/bin/rustc" "${_stage}/rust-${_v}/bin/cargo"
  tar -czf "${DOWNLOAD_DIR}/rust/rust-${_v}.tar.gz" -C "${_stage}" "rust-${_v}"
}

# ## make_mock_rust_target_archives
# Builds synthetic rust-std target and clippy component tarballs for offline testing.
make_mock_rust_target_archives() {
  _v="$1"
  _tgt="$2"
  _stage="${TEST_TMP}/stage_rust_sub_${_v}"
  mkdir -p "${_stage}/rust-std-${_v}-${_tgt}/lib/rustlib/${_tgt}/lib" "${_stage}/clippy-${_v}/bin" "${DOWNLOAD_DIR}/rust"
  printf 'rlib\n' > "${_stage}/rust-std-${_v}-${_tgt}/lib/rustlib/${_tgt}/lib/libcore.rlib"
  cat > "${_stage}/clippy-${_v}/bin/cargo-clippy" << EOF
#!/bin/sh
printf 'clippy %s\n' "${_v}"
EOF
  chmod 755 "${_stage}/clippy-${_v}/bin/cargo-clippy"
  tar -czf "${DOWNLOAD_DIR}/rust/rust-std-${_v}-${_tgt}.tar.gz" -C "${_stage}" "rust-std-${_v}-${_tgt}"
  tar -czf "${DOWNLOAD_DIR}/rust/clippy-${_v}.tar.gz" -C "${_stage}" "clippy-${_v}"
}

# ## make_mock_node_archive
# Builds a synthetic standalone Node.js tarball matching host OS/arch for offline testing.
make_mock_node_archive() {
  _v="$1"
  _os="${UNAME_LOWER:-linux}"
  case "$_os" in darwin*) _os='darwin' ;; *) _os='linux' ;; esac
  _arch="${ARCH:-x86_64}"
  case "$_arch" in x86_64|amd64) _arch='x64' ;; aarch64|arm64) _arch='arm64' ;; esac
  _stage="${TEST_TMP}/stage_node_${_v}"
  mkdir -p "${_stage}/node-v${_v}-${_os}-${_arch}/bin" "${DOWNLOAD_DIR}/nodejs"
  cat > "${_stage}/node-v${_v}-${_os}-${_arch}/bin/node" << EOF
#!/bin/sh
printf 'v%s\n' "${_v}"
EOF
  chmod 755 "${_stage}/node-v${_v}-${_os}-${_arch}/bin/node"
  tar -czf "${DOWNLOAD_DIR}/nodejs/node-v${_v}-${_os}-${_arch}.tar.gz" -C "${_stage}" "node-v${_v}-${_os}-${_arch}"
}

# ## make_mock_python_archive
# Builds a synthetic standalone CPython tarball for offline side-by-side testing.
make_mock_python_archive() {
  _v="$1"
  _stage="${TEST_TMP}/stage_py_${_v}"
  mkdir -p "${_stage}/python-${_v}/bin" "${DOWNLOAD_DIR}/python"
  cat > "${_stage}/python-${_v}/bin/python3" << EOF
#!/bin/sh
printf 'Python %s\n' "${_v}"
EOF
  chmod 755 "${_stage}/python-${_v}/bin/python3"
  tar -czf "${DOWNLOAD_DIR}/python/python-${_v}.tar.gz" -C "${_stage}" "python-${_v}"
}

printf '%s\n' '=== 1. Capability Enforcement (Daemon Verb Rejection on Compiler) ==='
if "${LIBSCRIPT_ROOT_DIR}/_lib/languages/rust/cli.sh" start rust 1.85.0 >/dev/null 2>&1; then
  fail_test 'Expected start on non-daemon rust to fail with non-zero exit code'
fi

printf '%s\n' '=== 2. Rust Side-by-Side 2x Idempotent Install, O(1) bin Farm, & Sub-Targets ==='
make_mock_rust_archive '1.84.0'
make_mock_rust_archive '1.85.0'
make_mock_rust_target_archives '1.85.0' 'wasm32-unknown-unknown'

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install rust 1.84.0 --offline --download-dir="${DOWNLOAD_DIR}"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install rust 1.84.0 --offline --download-dir="${DOWNLOAD_DIR}"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install rust 1.85.0 --offline --download-dir="${DOWNLOAD_DIR}" --targets=wasm32-unknown-unknown --components=clippy --use

[ -x "${LIBSCRIPT_HOME}/bin/rustc" ] || fail_test "Expected active rustc symlink in ${LIBSCRIPT_HOME}/bin/rustc"
[ -x "${LIBSCRIPT_HOME}/bin/cargo-clippy" ] || fail_test "Expected cargo-clippy symlink in ${LIBSCRIPT_HOME}/bin"
_rc_out=$("${LIBSCRIPT_HOME}/bin/rustc" --version)
case "$_rc_out" in
  *"1.85.0"*) ;;
  *) fail_test "Expected active rustc 1.85.0, got: ${_rc_out}" ;;
esac

_targets_out=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" target-ls rust 1.85.0)
printf '%s\n' "$_targets_out" | grep -qx 'wasm32-unknown-unknown' || fail_test 'wasm32-unknown-unknown missing from target-ls'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" target-add rust 1.85.0 wasm32-unknown-unknown --download-dir="${DOWNLOAD_DIR}"
_comps_out=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" component-ls rust 1.85.0)
printf '%s\n' "$_comps_out" | grep -qx 'clippy' || fail_test 'clippy missing from component-ls'

"${LIBSCRIPT_ROOT_DIR}/libscript.sh" use rust 1.84.0
_rc_switched=$("${LIBSCRIPT_HOME}/bin/rustc" --version)
case "$_rc_switched" in
  *"1.84.0"*) ;;
  *) fail_test "Expected switched rustc 1.84.0, got: ${_rc_switched}" ;;
esac

printf '%s\n' '=== 3. Node.js & Python Side-by-Side Isolation + NPM_CONFIG_PREFIX ==='
make_mock_node_archive '20.18.0'
make_mock_node_archive '22.14.0'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install nodejs 20.18.0 --offline --download-dir="${DOWNLOAD_DIR}"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install nodejs 22.14.0 --offline --download-dir="${DOWNLOAD_DIR}" --use
[ "$("${LIBSCRIPT_HOME}/bin/node" -v)" = 'v22.14.0' ] || fail_test 'Expected active node v22.14.0 in LIBSCRIPT_HOME/bin'

make_mock_python_archive '3.11.9'
make_mock_python_archive '3.12.8'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install python 3.11.9 --offline --download-dir="${DOWNLOAD_DIR}"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" install python 3.12.8 --offline --download-dir="${DOWNLOAD_DIR}" --use
[ "$("${LIBSCRIPT_HOME}/python/3.11.9/bin/python3" --version)" = 'Python 3.11.9' ] || fail_test 'Python 3.11.9 not strictly isolated'
[ "$("${LIBSCRIPT_HOME}/bin/python3" --version)" = 'Python 3.12.8' ] || fail_test 'Expected active Python 3.12.8 in LIBSCRIPT_HOME/bin'

printf '%s\n' '=== 4. Multi-Tool .libscript-version Upward Workspace Resolution (Zero eval) ==='
mkdir -p "${TEST_TMP}/ws/sub/pkg"
cat > "${TEST_TMP}/ws/.libscript-version" << 'EOF'
# Workspace toolchain pins
rust=1.84.0
nodejs=20.18.0
python=3.11.9
EOF
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" resolve-env --dir="${TEST_TMP}/ws/sub/pkg" --write="${TEST_TMP}/ws_env.sh"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" resolve-env --dir="${TEST_TMP}/ws/sub/pkg" --write="${TEST_TMP}/ws_env.sh"
_ws_check=$(
  # shellcheck disable=SC1090,SC1091
  . "${TEST_TMP}/ws_env.sh"
  printf '%s|%s|%s|%s\n' "$(rustc --version)" "$(node -v)" "$(python3 --version)" "${NPM_CONFIG_PREFIX}"
)
case "$_ws_check" in
  *"1.84.0"*"|v20.18.0|Python 3.11.9|"*20.18.0) ;;
  *) fail_test "Unexpected workspace resolved environment: ${_ws_check}" ;;
esac

printf '%s\n' '=== 5. Uninstall Active Version Redirects Shims & Cleans Stale Links ==='
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" use rust 1.85.0
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" uninstall rust 1.85.0
[ -x "${LIBSCRIPT_HOME}/bin/rustc" ] || fail_test 'Expected rustc shim to redirect to remaining 1.84.0 after uninstalling 1.85.0'
case "$("${LIBSCRIPT_HOME}/bin/rustc" --version)" in
  *"1.84.0"*) ;;
  *) fail_test 'Expected fallback to 1.84.0 after uninstalling 1.85.0' ;;
esac
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" uninstall rust 1.84.0
[ ! -e "${LIBSCRIPT_HOME}/bin/rustc" ] || fail_test 'Expected rustc shim to be removed after uninstalling last version'

rm -rf "${TEST_TMP}"
printf '%s\n' '[PASS] All Pillar 1 Version Manager Replacement tests passed!'
exit 0
