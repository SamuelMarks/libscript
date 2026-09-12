#!/bin/sh
# ## Overview
# Validates run_native_tests.sh execution, verifying CLI options, OS detection,
# dry-run mode, manifest filtering, and output artifact creation.
#
# ## Usage
# ./tests/test_run_native_tests.sh

set -eu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
THIS_DIR="${SCRIPT_DIR}"
: "${THIS_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## run_tests
# Creates a temporary mock environment and verifies run_native_tests.sh execution.
run_tests() {
  _test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/test_run_native.XXXXXX")

  mkdir -p "${_test_tmp}/_lib/catA/compA"
  mkdir -p "${_test_tmp}/_lib/catB/compB"
  mkdir -p "${_test_tmp}/_lib/_common"
  mkdir -p "${_test_tmp}/tests"

  # Mock libscript.sh
  cat <<'EOF_LIBSCRIPT' >"${_test_tmp}/libscript.sh"
#!/bin/sh
set -e
exit 0
EOF_LIBSCRIPT
  chmod +x "${_test_tmp}/libscript.sh"

  # Manifest for compA (whitelist all)
  cat <<'EOF_MAN' >"${_test_tmp}/_lib/catA/compA/manifest.json"
{
  "name": "compA",
  "os_whitelist": ["all"],
  "os_blacklist": []
}
EOF_MAN

  # Manifest for compB (blacklisted on freebsd)
  cat <<'EOF_MANB' >"${_test_tmp}/_lib/catB/compB/manifest.json"
{
  "name": "compB",
  "os_whitelist": ["all"],
  "os_blacklist": ["freebsd"]
}
EOF_MANB

  # Copy runner scripts
  cp "${REPO_ROOT}/tests/run_native_tests.sh" "${_test_tmp}/tests/run_native_tests.sh"
  if [ -f "${REPO_ROOT}/tests/update_results.sh" ]; then
    cp "${REPO_ROOT}/tests/update_results.sh" "${_test_tmp}/tests/update_results.sh"
    chmod +x "${_test_tmp}/tests/update_results.sh"
  fi
  chmod +x "${_test_tmp}/tests/run_native_tests.sh"

  cat <<'EOF_README' >"${_test_tmp}/README.md"
# Mock Project

## Supported Components

| Component | Linux (apk) | Linux (deb) | Linux (rpm) | Windows | SunOS | FreeBSD |
|---|---|---|---|---|---|---|
| `compA` | ❓ | ❓ | ❓ | - | - | - |
| `compB` | ❓ | ❓ | ❓ | - | - | - |

## License
MIT
EOF_README

  # Test 1: Dry run with Alpine OS
  (
    cd "${_test_tmp}"
    "./tests/run_native_tests.sh" --dry-run --os alpine compA
  )

  if [ ! -f "${_test_tmp}/tests_tmp/compA.linux.alpine.success" ]; then
    printf 'Error: compA.linux.alpine.success not created
' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  # Test 2: Dry run with FreeBSD OS on blacklisted compB
  (
    cd "${_test_tmp}"
    "./tests/run_native_tests.sh" --dry-run --os freebsd compB
  )

  if [ -f "${_test_tmp}/tests_tmp/compB.freebsd.success" ]; then
    printf 'Error: compB should have been skipped on freebsd
' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  # Test 3: Dry run with category flag
  (
    cd "${_test_tmp}"
    "./tests/run_native_tests.sh" --dry-run --os debian --category catA
  )

  if [ ! -f "${_test_tmp}/tests_tmp/compA.linux.debian.success" ]; then
    printf 'Error: compA.linux.debian.success not created from category run
' >&2
    rm -rf "${_test_tmp}"
    exit 1
  fi

  rm -rf "${_test_tmp}"
  printf 'run_native_tests.sh tests passed successfully.
'
}

run_tests
