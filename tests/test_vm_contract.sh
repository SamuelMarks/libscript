#!/bin/sh
# ## Overview
# Behavioral test suite verifying the LibScript Version Manager Contract (`WHAT_A_VERSION_MANAGER_SHOULD_LOOK_LIKE.md`).
#
# ## Usage
# ./tests/test_vm_contract.sh

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

TEST_SANDBOX=$(mktemp -d)
trap 'rm -rf "$TEST_SANDBOX"' EXIT INT TERM

export HOME="${TEST_SANDBOX}/home"
export LIBSCRIPT_HOME="${TEST_SANDBOX}/libscript_home"
export LIBSCRIPT_CACHE_DIR="${TEST_SANDBOX}/cache"
mkdir -p "$HOME" "$LIBSCRIPT_HOME" "$LIBSCRIPT_CACHE_DIR"

FAILURES=0

# ## assert_contains
# Asserts that a string contains a given substring.
assert_contains() {
  _haystack="$1"
  _needle="$2"
  _label="$3"
  case "$_haystack" in
    *"$_needle"*)
      printf '[PASS] %s
' "$_label"
      ;;
    *)
      printf '[FAIL] %s (expected "%s" in output)
' "$_label" "$_needle" >&2
      FAILURES=$((FAILURES + 1))
      ;;
  esac
}

# ## test_non_invasive_isolation
# Verifies that version manager operations never mutate user shell profiles.
test_non_invasive_isolation() {
  printf '==> 1. Testing Non-Invasive Environment Isolation...
'
  printf '# sentinel-bashrc
' > "${HOME}/.bashrc"
  printf '# sentinel-profile
' > "${HOME}/.profile"
  printf '# sentinel-zshrc
' > "${HOME}/.zshrc"

  sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" --help >/dev/null

  if [ "$(cat "${HOME}/.bashrc")" = "# sentinel-bashrc" ] && 
     [ "$(cat "${HOME}/.profile")" = "# sentinel-profile" ] && 
     [ "$(cat "${HOME}/.zshrc")" = "# sentinel-zshrc" ]; then
    printf '[PASS] Shell profiles (~/.bashrc, ~/.profile, ~/.zshrc) untouched.
'
  else
    printf '[FAIL] Shell profiles were mutated!
' >&2
    FAILURES=$((FAILURES + 1))
  fi
}

# ## test_side_by_side_multi_version
# Verifies side-by-side coexistence of two versions (1.6 and 1.7.1) and switching via which/exec/run/info.
test_side_by_side_multi_version() {
  printf '==> 2. Testing Side-by-Side Multi-Version Coexistence...
'
  mkdir -p "${LIBSCRIPT_HOME}/jq/1.6/bin" "${LIBSCRIPT_HOME}/jq/1.7.1/bin" "${LIBSCRIPT_HOME}/jq/1.7.1/lib" "${LIBSCRIPT_HOME}/jq/1.7.1/include"

  cat <<'EOF' > "${LIBSCRIPT_HOME}/jq/1.6/bin/jq"
#!/bin/sh
printf 'jq-1.6-isolated %s
' "$*"
EOF
  cat <<'EOF' > "${LIBSCRIPT_HOME}/jq/1.7.1/bin/jq"
#!/bin/sh
printf 'jq-1.7.1-isolated %s
' "$*"
EOF
  chmod +x "${LIBSCRIPT_HOME}/jq/1.6/bin/jq" "${LIBSCRIPT_HOME}/jq/1.7.1/bin/jq"

  _which_16=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" which jq 1.6 2>&1)
  _which_17=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" which jq 1.7.1 2>&1)
  assert_contains "$_which_16" "${LIBSCRIPT_HOME}/jq/1.6/bin/jq" "which resolves jq 1.6 isolated binary"
  assert_contains "$_which_17" "${LIBSCRIPT_HOME}/jq/1.7.1/bin/jq" "which resolves jq 1.7.1 isolated binary"

  _run_16=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" run jq 1.6 --version)
  _run_17=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" run jq 1.7.1 --version)
  assert_contains "$_run_16" "jq-1.6-isolated --version" "run executes jq 1.6 binary directly"
  assert_contains "$_run_17" "jq-1.7.1-isolated --version" "run executes jq 1.7.1 binary directly"

  _exec_16=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" exec jq 1.6 jq --check)
  _exec_17=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" exec jq 1.7.1 jq --check)
  assert_contains "$_exec_16" "jq-1.6-isolated --check" "exec scopes PATH to jq 1.6"
  assert_contains "$_exec_17" "jq-1.7.1-isolated --check" "exec scopes PATH to jq 1.7.1"

  _info_17=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" info jq 1.7.1)
  assert_contains "$_info_17" "Status: Installed" "info detects installed jq 1.7.1"
}

# ## test_scoped_env_formats
# Verifies env output across sh, cmd, ps1, fish, and json formats.
test_scoped_env_formats() {
  printf '==> 3. Testing Scoped env Output Format Matrix...
'
  _env_sh=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" env jq 1.7.1 --format=sh)
  _env_cmd=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" env jq 1.7.1 --format=cmd)
  _env_ps1=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" env jq 1.7.1 --format=ps1)
  _env_fish=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" env jq 1.7.1 --format=fish)
  _env_json=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" env jq 1.7.1 --format=json)

  assert_contains "$_env_sh" 'export PATH=' "env --format=sh emits POSIX export PATH"
  assert_contains "$_env_cmd" 'SET "PATH=' "env --format=cmd emits Windows Batch SET PATH"
  assert_contains "$_env_ps1" '$env:PATH =' "env --format=ps1 emits PowerShell \$env:PATH"
  assert_contains "$_env_fish" 'set -gx PATH' "env --format=fish emits Fish set -gx PATH"
  assert_contains "$_env_json" '"PATH":' "env --format=json emits JSON PATH key"
}

# ## test_offline_and_dependency_flags
# Verifies offline cache flags, dependency strategies, and multi-instance service flags in component_core.sh.
test_offline_and_dependency_flags() {
  printf '==> 4. Testing Offline Cache, Dependency Strategy & Multi-Instance Flags...\n'
  _help_out=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/databases/postgres/cli.sh" --help 2>&1)
  assert_contains "$_help_out" "install-service" "CLI router exposes install-service verb"
  assert_contains "$_help_out" "uninstall-service" "CLI router exposes uninstall-service verb"
  assert_contains "$_help_out" "ls-remote" "CLI router exposes ls-remote verb"
  assert_contains "$_help_out" "download" "CLI router exposes download verb"

  _env_offline=$(sh "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/cli.sh" env jq 1.7.1 --force-offline --cache-dir="${LIBSCRIPT_CACHE_DIR}" --service-name=custom_jq --C_TOOLCHAIN_STRATEGY=reuse --format=sh)
  assert_contains "$_env_offline" "${LIBSCRIPT_HOME}/jq/1.7.1/bin" "CLI router parses --force-offline, --cache-dir, --service-name, and --*_STRATEGY cleanly"
}

printf '=== LibScript Behavioral Version Manager Contract Suite ===
'
test_non_invasive_isolation
test_side_by_side_multi_version
test_scoped_env_formats
test_offline_and_dependency_flags

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] Behavioral Version Manager Contract Suite failed with %d failure(s)!
' "$FAILURES" >&2
  exit 1
fi

printf '=== All Behavioral Version Manager Contract Checks Passed! ===
'
exit 0
