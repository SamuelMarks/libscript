#!/bin/sh
# ## Overview
# Enforces zero-PowerShell regression verification by prepending fail-closed `powershell` and `pwsh` poison shims (exit 99) to `PATH` before running core suites.
# ## Usage
# ./tests/run_zero_powershell_suite.sh

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

POISON_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ls_no_ps.XXXXXX")
trap 'rm -rf "${POISON_DIR}"' EXIT INT TERM

for _ps in powershell powershell.exe pwsh pwsh.exe; do
  cat << 'EOF_SHIM' > "${POISON_DIR}/${_ps}"
#!/bin/sh
printf '[ERROR] Forbidden PowerShell invocation in zero-PowerShell suite!\n' >&2
exit 99
EOF_SHIM
  chmod +x "${POISON_DIR}/${_ps}"
done

PATH="${POISON_DIR}:${PATH}"
export PATH

set +e
powershell -Command "exit 0" >/dev/null 2>&1
PS_RC=$?
set -e
if [ "${PS_RC}" -ne 99 ]; then
  printf '[FAIL] Expected poison powershell shim to exit 99, got %s\n' "${PS_RC}" >&2
  exit 1
fi

unset STACK || true
"${LIBSCRIPT_ROOT_DIR}/tests/test_win_dos_component_pm.sh" || exit 1
"${LIBSCRIPT_ROOT_DIR}/tests/test_standards_adherence.sh" || exit 1
"${LIBSCRIPT_ROOT_DIR}/tests/test_qemu_msdos_smoke.sh" || exit 1
STACK="" "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_cmd.sh" "${LIBSCRIPT_ROOT_DIR}/tests/run_zero_powershell_suite.cmd" "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_cmd.cmd" || exit 1

printf '%s\n' '[PASS] Zero-PowerShell suite completed with poison shims active.'
exit 0
