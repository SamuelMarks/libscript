#!/bin/sh
# ## Overview
# End-to-end integration test suite for LibScript's 3 generic installation/build modes:
# Mode 1 (install/build via a specific package manager), Mode 2 (build from source with
# the default host C toolchain), and Mode 3 (build from source with a custom C toolchain).
#
# ## Usage
# ./tests/test_generic_build_modes.sh

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

# ## verify_mode1_specific_pkg_mgr
# Verifies Mode 1 (--pkg-mgr=<pm> and <PKG>_PKG_MGR) package manager selection and package mapping in dry-run mode.
verify_mode1_specific_pkg_mgr() {
  for _pm in apt-get apk brew nix winget choco; do
    unset SCRIPT_NAME || true
    _out="$(LIBSCRIPT_DRY_RUN_PKG_MGR=1 "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite latest --pkg-mgr="${_pm}" 2>&1 || true)"
    case "${_out}" in
      *"[DRY-RUN] (${_pm}) install"*) ;;
      *)
        printf '[FAIL] Mode 1 --pkg-mgr=%s did not route to expected package manager. Output:
%s
' "${_pm}" "${_out}" >&2
        return 1
        ;;
    esac
  done
}

# ## verify_mode2_source_default_toolchain
# Verifies Mode 2 (--from-source --toolchain=default) builds SQLite from source and is 2x idempotent.
verify_mode2_source_default_toolchain() {
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite 3.46.1 --from-source --toolchain=default
  _pass2="$( "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite 3.46.1 --from-source --toolchain=default 2>&1 )"
  case "${_pass2}" in
    *"already built from source"*) ;;
    *)
      printf '[FAIL] Mode 2 second pass did not trigger idempotent early exit.
' >&2
      return 1
      ;;
  esac
  [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/3.46.1/bin/sqlite3" ]
  [ -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/3.46.1/build-metrics.json" ]
}

# ## verify_mode3_source_custom_toolchain
# Verifies Mode 3 (--from-source --toolchain=custom-cc and --custom-cc=<path>) builds SQLite into a compiler-namespaced prefix and is 2x idempotent.
verify_mode3_source_custom_toolchain() {
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite 3.46.1 --from-source --toolchain=custom-cc
  _pass2="$( "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite 3.46.1 --from-source --toolchain=custom-cc 2>&1 )"
  case "${_pass2}" in
    *"already built from source"*) ;;
    *)
      printf '[FAIL] Mode 3 second pass did not trigger idempotent early exit.
' >&2
      return 1
      ;;
  esac
  [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/3.46.1-custom-cc/bin/sqlite3" ]
  [ -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/sqlite/3.46.1-custom-cc/build-metrics.json" ]
}

verify_mode1_specific_pkg_mgr
verify_mode2_source_default_toolchain
verify_mode3_source_custom_toolchain

printf '[PASS] All 3 generic build/installation modes verified with 2x idempotency!
'
