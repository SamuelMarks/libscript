#!/bin/sh
# ## Overview
# Unit test suite for T0 DOS triplets (ia16-pc-msdos, i386-pc-msdoswatcom, i586-pc-msdosdjgpp)
# and T0 resolve_stack.jq DOS capability strata (positive 4-stage resolution + DOS1_FLAT_FCB_ONLY,
# DOS2_NO_DPMI32, and DOS_INCOMPATIBLE_FORK rejection guards).
#
# ## Usage
# ./tests/test_dos_solver.sh

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

WORK="${TMPDIR:-/tmp}/dos_solver_test_$$"
mkdir -p "${WORK}"
trap 'rm -rf "${WORK}"' EXIT INT TERM

# ## check_triplet
# Sources triplets.sh in a subshell and verifies LIBSCRIPT_TARGET_TRIPLET and absence of ELF-only flags.
check_triplet() {
  _ct_arch="$1"
  _ct_libc="$2"
  _ct_os="$3"
  _ct_exp="$4"
  (
    LIBSCRIPT_TRIPLETS_QUIET=1
    export LIBSCRIPT_TRIPLETS_QUIET
    set -- "${_ct_arch}" "${_ct_libc}" "${_ct_os}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/target/triplets.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
    [ "${LIBSCRIPT_TARGET_TRIPLET}" = "${_ct_exp}" ]
    case "${LIBSCRIPT_SECURITY_CFLAGS} ${LIBSCRIPT_SECURITY_LDFLAGS}" in
      *-fPIC*|*relro*) exit 1 ;;
    esac
  )
}

check_triplet 'i8086' 'dos-fcb-none' 'msdos' 'ia16-pc-msdos'
check_triplet 'i8086' 'dos16-libc' 'msdos' 'ia16-pc-msdos'
check_triplet 'i386' 'watcom-libc' 'msdos' 'i386-pc-msdoswatcom'
check_triplet 'i586' 'djgpp-libc' 'freedos' 'i586-pc-msdosdjgpp'

# Positive profile resolution across all 4 DOS reference profiles
for _prof in \
  freedos-1.4-djgpp-i586 \
  msdos-4.0-djgpp-i586 \
  msdos-2.0-realmode-i8086 \
  msdos-1.25-heritage-i8086; do
  STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" \
    "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/${_prof}.json" \
    "${WORK}/${_prof}.plan.json"
  jq -e '.stages | length == 4' "${WORK}/${_prof}.plan.json" >/dev/null
  jq -e '[.stages[] | select(.stage == "stage2-target-sysroot") | .tasks[].name] | index("win-cmd-asm") != null' "${WORK}/${_prof}.plan.json" >/dev/null
  jq -e '.stages[] | select(.stage == "stage3-media-packaging") | .tasks[0].component == "synthesis/distro/dos"' "${WORK}/${_prof}.plan.json" >/dev/null
done

# Verify win-cmd-rs resolves on both FreeDOS 1.4 and MS-DOS 4.00
for _d32_prof in freedos-1.4-djgpp-i586 msdos-4.0-djgpp-i586; do
  jq -e '[.stages[] | select(.stage == "stage2-target-sysroot") | .tasks[].name] | index("win-cmd-rs") != null' "${WORK}/${_d32_prof}.plan.json" >/dev/null
done

# Positive rich userland stack on FreeDOS 1.4 & MS-DOS 4.00
for _rich_base in freedos-1.4-djgpp-i586 msdos-4.0-djgpp-i586; do
  jq '.components = ["jq", "gawk", "toybox", "dash", "sqlite-tools", "win-cmd-rs", "win-cmd-asm"]' \
    "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/${_rich_base}.json" > "${WORK}/${_rich_base}_rich.json"
  STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" "${WORK}/${_rich_base}_rich.json" "${WORK}/${_rich_base}_rich.plan.json"
  jq -e '[.stages[] | select(.stage == "stage2-target-sysroot") | .tasks[].name] | (index("jq") != null and index("win-cmd-rs") != null and index("win-cmd-asm") != null and index("sqlite-tools") != null)' \
    "${WORK}/${_rich_base}_rich.plan.json" >/dev/null
done

# Negative guard 1: DOS1_FLAT_FCB_ONLY (MS-DOS 1.25 + jq or win-cmd-rs)
for _bad125_pkg in jq win-cmd-rs; do
  jq --arg p "${_bad125_pkg}" '.components = [$p]' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/msdos-1.25-heritage-i8086.json" > "${WORK}/bad_125_${_bad125_pkg}.json"
  set +e
  _err1=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" "${WORK}/bad_125_${_bad125_pkg}.json" 2>&1)
  _rc1=$?
  set -e
  [ "${_rc1}" -ne 0 ]
  printf '%s\n' "${_err1}" | grep -q 'DOS1_FLAT_FCB_ONLY'
done

# Negative guard 2: DOS2_NO_DPMI32 (MS-DOS 2.0 + jq or win-cmd-rs)
for _bad20_pkg in jq win-cmd-rs; do
  jq --arg p "${_bad20_pkg}" '.components = [$p]' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/msdos-2.0-realmode-i8086.json" > "${WORK}/bad_20_${_bad20_pkg}.json"
  set +e
  _err2=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" "${WORK}/bad_20_${_bad20_pkg}.json" 2>&1)
  _rc2=$?
  set -e
  [ "${_rc2}" -ne 0 ]
  printf '%s\n' "${_err2}" | grep -q 'DOS2_NO_DPMI32'
done

# Negative guard 3: DOS_INCOMPATIBLE_FORK (FreeDOS + postgres / nginx)
for _badfork_pkg in postgres nginx; do
  jq --arg p "${_badfork_pkg}" '.components = [$p]' "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/freedos-1.4-djgpp-i586.json" > "${WORK}/bad_fork_${_badfork_pkg}.json"
  set +e
  _err3=$(STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" "${WORK}/bad_fork_${_badfork_pkg}.json" 2>&1)
  _rc3=$?
  set -e
  [ "${_rc3}" -ne 0 ]
  printf '%s\n' "${_err3}" | grep -q 'DOS_INCOMPATIBLE_FORK'
done

printf '[PASS] DOS T0 triplets and multi-stratum constraint solver verified.\n'
