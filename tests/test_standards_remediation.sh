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

printf '==> [5/7] Testing catalog.sh --clean-base and Git core.hooksPath...\n'
_cb_out=$(STACK='' /bin/sh "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/preloader/catalog.sh" --clean-base 2>/dev/null)
assert_eq '[]' "${_cb_out}" "catalog.sh --clean-base"
_hooks_path=$(git -C "${LIBSCRIPT_ROOT_DIR}" config --local --get core.hooksPath || true)
assert_eq '.githooks' "${_hooks_path}" "git core.hooksPath configured to .githooks"

printf '==> [6/7] Testing repeat [STOP] shared library sourcing preserves THIS_FILE & SCRIPT_DIR...\n'
for _s_lib in "${LIBSCRIPT_ROOT_DIR}/engine/common/semver.sh" "${LIBSCRIPT_ROOT_DIR}/engine/common/env_printer.sh" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_83.sh"; do
  SCRIPT_NAME="${_s_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  assert_eq "${_orig_this}" "${THIS_FILE}" "1st source of ${_s_lib} preserves THIS_FILE"
  assert_eq "${_orig_dir}" "${SCRIPT_DIR}" "1st source of ${_s_lib} preserves SCRIPT_DIR"
  # Force a [STOP] hit by pre-populating STACK and sourcing again
  _saved_st="${STACK}"
  export STACK="${STACK}${_s_lib}:"
  SCRIPT_NAME="${_s_lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  export STACK="${_saved_st}"
  assert_eq "${_orig_this}" "${THIS_FILE}" "[STOP] repeat source of ${_s_lib} preserves THIS_FILE"
  assert_eq "${_orig_dir}" "${SCRIPT_DIR}" "[STOP] repeat source of ${_s_lib} preserves SCRIPT_DIR"
done

printf '==> [7/10] Testing SET_F_NOGLOB, compound BAN_EVAL, and audit_stacks --strict...\n'
_bad_sh="${TEST_TMP}/bad_noglob.sh"
cat <<'EOF_BAD' > "${_bad_sh}"
#!/bin/sh
# ## Overview
# Synthetic test fixture verifying SET_F_NOGLOB and compound BAN_EVAL detection.
# ## Usage
# ./bad_noglob.sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then THIS_FILE="${SCRIPT_NAME}"; else THIS_FILE="${0}"; fi
case "${STACK+x}" in *':'"${THIS_FILE}"':'*) exit 0 ;; esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=${SCRIPT_DIR}}"
for f in "${SCRIPT_DIR}"/*; do
  printf '%s\n' "$f"
done
true && eval 'printf ok'
EOF_BAD
printf '@echo off\r\n' > "${TEST_TMP}/bad_noglob.cmd"
if STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_posix.sh" "${_bad_sh}" >/dev/null 2>&1; then
  printf '[FAIL] audit_posix.sh failed to reject unquoted glob under set -f!\n' >&2
  exit 1
fi
if STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.sh" "${_bad_sh}" >/dev/null 2>&1; then
  printf '[FAIL] audit_standards.sh failed to reject compound && eval!\n' >&2
  exit 1
fi
STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_stacks.sh" --strict >/dev/null

printf '==> [8/10] Testing 2x sourcing preservation across infrastructure, workloads, synthesis, docker, and helper scripts...\n'
for _ext_src in \
  'infrastructure/providers/aws/env.sh' \
  'workloads/apps/wordpress/env.sh' \
  'synthesis/distro/bento/env.sh' \
  'synthesis/distro/dos/env.sh' \
  'engine/common/_noop/env.sh' \
  'docker/conf_no_all.env.sh' \
  'engine/common/service_install.sh' \
  'engine/common/elf_verneed_patch.sh' \
  'vagrant/_common/dos_ctest_common.sh' \
  'experiments/_common/guest_capture_agent.sh'; do
  _saved_st="${STACK}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ext_src}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1
  assert_eq "${_orig_this}" "${THIS_FILE}" "1st source of ${_ext_src} preserves THIS_FILE"
  assert_eq "${_orig_dir}" "${SCRIPT_DIR}" "1st source of ${_ext_src} preserves SCRIPT_DIR"
  assert_eq '' "${SCRIPT_NAME-}" "1st source of ${_ext_src} unsets SCRIPT_NAME"
  export STACK=":${LIBSCRIPT_ROOT_DIR}/${_ext_src}:"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ext_src}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}" >/dev/null 2>&1
  export STACK="${_saved_st}"
  assert_eq "${_orig_this}" "${THIS_FILE}" "2nd [STOP] source of ${_ext_src} preserves THIS_FILE"
  assert_eq "${_orig_dir}" "${SCRIPT_DIR}" "2nd [STOP] source of ${_ext_src} preserves SCRIPT_DIR"
  assert_eq '' "${SCRIPT_NAME-}" "2nd [STOP] source of ${_ext_src} unsets SCRIPT_NAME"
done

printf '==> [9/10] Testing docker/create_docker_builder.sh 2x idempotency and .cmd companion generation...\n'
_dk_tmp="${TEST_TMP}/dk_gen"
mkdir -p "${_dk_tmp}/docker"
cp "${LIBSCRIPT_ROOT_DIR}/docker/base.alpine.Dockerfile" "${_dk_tmp}/docker/base.alpine.Dockerfile"
STACK='' "${LIBSCRIPT_ROOT_DIR}/docker/create_docker_builder.sh" -i "${_dk_tmp}" >/dev/null
_dk_hash1=$(cksum "${_dk_tmp}/docker_builder.sh" "${_dk_tmp}/docker_builder_parallel.sh" "${_dk_tmp}/docker_builder.cmd" "${_dk_tmp}/docker_builder_parallel.cmd")
STACK='' "${LIBSCRIPT_ROOT_DIR}/docker/create_docker_builder.sh" -i "${_dk_tmp}" >/dev/null
_dk_hash2=$(cksum "${_dk_tmp}/docker_builder.sh" "${_dk_tmp}/docker_builder_parallel.sh" "${_dk_tmp}/docker_builder.cmd" "${_dk_tmp}/docker_builder_parallel.cmd")
assert_eq "${_dk_hash1}" "${_dk_hash2}" "docker/create_docker_builder.sh is strictly 2x idempotent and emits parallel .cmd companion"

printf '==> [10/10] Testing static linter rejection of EMPTY_BATCH_BLOCK, heredoc Python, test ==, and ps -q...\n'
_bad_cmd="${TEST_TMP}/bad_empty_block.cmd"
printf '@echo off\r\n:: # bad_empty_block.cmd\r\n:: ## Overview\r\n:: Synthetic fixture.\r\n:: ## Usage\r\n:: bad_empty_block.cmd\r\nsetlocal EnableDelayedExpansion\r\nset "THIS_FILE=%%~f0"\r\nif defined STACK (\r\n  echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1\r\n  if not errorlevel 1 exit /b 0\r\n)\r\nset "LIBSCRIPT_ROOT_DIR=."\r\nif not defined LIBSCRIPT_ROOT_DIR (\r\n)\r\nexit /b 0\r\n' > "${_bad_cmd}"
printf '#!/bin/sh\n' > "${TEST_TMP}/bad_empty_block.sh"
if STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.sh" "${_bad_cmd}" 2>&1 | grep -q 'EMPTY_BATCH_BLOCK'; then
  :
else
  printf '[FAIL] audit_standards.sh failed to detect EMPTY_BATCH_BLOCK!\n' >&2
  exit 1
fi
_bad_posix="${TEST_TMP}/bad_bashism.sh"
cat <<'EOF_BP' > "${_bad_posix}"
#!/bin/sh
# ## Overview
# Synthetic fixture verifying test == and ps -q rejection.
# ## Usage
# ./bad_bashism.sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then THIS_FILE="${SCRIPT_NAME}"; else THIS_FILE="${0}"; fi
case "${STACK+x}" in *':'"${THIS_FILE}"':'*) exit 0 ;; esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=${SCRIPT_DIR}}"
if [ "$THIS_FILE" == "foo" ]; then
  ps -q 1 -o comm=
fi
EOF_BP
printf '@echo off\r\n' > "${TEST_TMP}/bad_bashism.cmd"
if STACK='' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_posix.sh" "${_bad_posix}" >/dev/null 2>&1; then
  printf '[FAIL] audit_posix.sh failed to reject [ == ] and ps -q!\n' >&2
  exit 1
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
printf '[PASS] All standards remediation regression checks passed!\n'
