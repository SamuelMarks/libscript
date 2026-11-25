#!/bin/sh
# ## Overview
# Regression suite verifying standards audit remediations: pure-POSIX URL parsing,
# dangling SCRIPT_NAME elimination in status.sh, caller THIS_FILE/SCRIPT_DIR preservation
# when sourcing env.sh and T0 git.sh, 2x directory symlink idempotency, and hook/tier invariants.
#
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
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ls_remediation_test.XXXXXX")
trap 'rm -rf "${TEST_TMP}"' EXIT HUP INT TERM

# ## assert_eq
# Asserts that two string values are equal, exiting with code 1 on mismatch.
assert_eq() {
  if [ "$1" != "$2" ]; then
    printf '[FAIL] %s: expected "%s", got "%s"\n' "${3:-assert_eq}" "$1" "$2" >&2
    exit 1
  fi
}

printf '==> [1/5] Testing pure-POSIX engine/common/url_parser.sh under /bin/sh -feu...\n'
_orig_this="${THIS_FILE}"
_orig_dir="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/url_parser.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
assert_eq "${_orig_this}" "${THIS_FILE}" "url_parser preserves THIS_FILE"
assert_eq "${_orig_dir}" "${SCRIPT_DIR}" "url_parser preserves SCRIPT_DIR"
protocol=''; user=''; pass=''; host=''; port=''; path=''; repo=''; branch=''
libscript_url_parser 'https://alice:s3cr3t@example.org:8443/org/repo.git' >/dev/null
assert_eq 'https://' "${protocol}" "url_parser protocol"
assert_eq 'alice' "${user}" "url_parser user"
assert_eq 's3cr3t' "${pass}" "url_parser pass"
assert_eq 'example.org' "${host}" "url_parser host"
assert_eq '8443' "${port}" "url_parser port"
assert_eq 'org/repo.git' "${path}" "url_parser path"
git_args_from_url 'https://github.com/SamuelMarks/libscript.git' 'master' >/dev/null
assert_eq 'https://github.com/SamuelMarks/libscript.git' "${repo}" "git_args_from_url repo"
assert_eq 'master' "${branch}" "git_args_from_url branch"

printf '==> [2/5] Testing _lib/*/*/env.sh & engine/common/git.sh caller context preservation...\n'
for _s_target in "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/bun-pm/env.sh" "${LIBSCRIPT_ROOT_DIR}/engine/common/git.sh"; do
  SCRIPT_NAME="${_s_target}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  assert_eq "${_orig_this}" "${THIS_FILE}" "sourced ${_s_target} preserves THIS_FILE"
  assert_eq "${_orig_dir}" "${SCRIPT_DIR}" "sourced ${_s_target} preserves SCRIPT_DIR"
  assert_eq "" "${SCRIPT_NAME-}" "sourced ${_s_target} unsets SCRIPT_NAME"
done

printf '==> [3/5] Testing status.sh execution under strict /bin/sh without unbound SCRIPT_NAME crash...\n'
for _st in "${LIBSCRIPT_ROOT_DIR}/_lib/caches/redis/status.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/nginx/status.sh"; do
  _st_err="${TEST_TMP}/status_err.txt"
  STACK='' /bin/sh "${_st}" >/dev/null 2>"${_st_err}" || true
  if grep -q 'SCRIPT_NAME: parameter not set' "${_st_err}" 2>/dev/null || grep -q 'unbound variable' "${_st_err}" 2>/dev/null; then
    printf '[FAIL] %s crashed with unbound SCRIPT_NAME: %s\n' "${_st}" "$(cat "${_st_err}")" >&2
    exit 1
  fi
done

printf '==> [4/5] Testing 2x directory symlink idempotency via versioning.sh...\n'
export LIBSCRIPT_HOME="${TEST_TMP}/home"
mkdir -p "${LIBSCRIPT_HOME}/demo/1.0.0/bin" "${LIBSCRIPT_HOME}/demo/2.0.0/bin"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
libscript_symlink_alias 'demo' 'latest' '1.0.0'
libscript_symlink_alias 'demo' 'latest' '1.0.0'
libscript_symlink_alias 'demo' 'latest' '2.0.0'
if [ -e "${LIBSCRIPT_HOME}/demo/1.0.0/1.0.0" ] || [ -e "${LIBSCRIPT_HOME}/demo/1.0.0/2.0.0" ] || [ -e "${LIBSCRIPT_HOME}/demo/2.0.0/2.0.0" ]; then
  printf '[FAIL] Nested symlink created inside target directory on repeated alias update!\n' >&2
  exit 1
fi

printf '==> [5/5] Testing catalog.sh --clean-base and Git core.hooksPath...\n'
_cb_out=$(STACK='' /bin/sh "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/preloader/catalog.sh" --clean-base 2>/dev/null)
assert_eq '[]' "${_cb_out}" "catalog.sh --clean-base"
_hooks_path=$(git -C "${LIBSCRIPT_ROOT_DIR}" config --local --get core.hooksPath || true)
assert_eq '.githooks' "${_hooks_path}" "git core.hooksPath configured to .githooks"

STACK="${STACK%"${THIS_FILE}":}"
export STACK
printf '[PASS] All standards remediation regression checks passed!\n'
