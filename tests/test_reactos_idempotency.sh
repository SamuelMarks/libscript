#!/bin/sh
# ## Overview
# 2-pass idempotency, multi-format export, and negative PE/OS guard verification test for ReactOS.
# Asserts Pass 2 produces exit code 0, emits [SKIP] markers, introduces zero filesystem churn,
# rejects cross-bitness PE headers (no WoW64), and rejects POSIX-only components in resolve_stack.
#
# ## Usage
# ./tests/test_reactos_idempotency.sh

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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${TMP_DIR}/home"
export LIBSCRIPT_OFFLINE=1
export LIBSCRIPT_ALLOW_STUB=1

TEST_SYS="${TMP_DIR}/sysroot-i686"
TEST_SYS64="${TMP_DIR}/sysroot-x64"

# Pass 1: Assemble i686 + x86_64 and export all 6 formats
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" \
  "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/minimal-headless-i686.json" "$TEST_SYS" >/dev/null
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" \
  "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/nightly-x86_64.json" "$TEST_SYS64" >/dev/null

for _fmt in iso raw qcow2 vhd vmdk box; do
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/reactos_distro.sh" \
    --format "$_fmt" \
    --profile "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/minimal-headless-i686.json" \
    --sysroot "$TEST_SYS" \
    --output "${TMP_DIR}/out.${_fmt}" >/dev/null
  [ -s "${TMP_DIR}/out.${_fmt}" ]
done

# Snapshot sysroot state after Pass 1
SNAP1="${TMP_DIR}/snap1.txt"
SNAP2="${TMP_DIR}/snap2.txt"
(cd "$TEST_SYS" && find . -type f | LC_ALL=C sort) > "$SNAP1"

# Pass 2: Assert [SKIP] and zero file churn
LOG_PASS2="${TMP_DIR}/pass2.log"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/assemble.sh" \
  "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/minimal-headless-i686.json" "$TEST_SYS" > "$LOG_PASS2" 2>&1
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/reactos_iso.sh" \
  "$TEST_SYS" "${TMP_DIR}/out.iso" >> "$LOG_PASS2" 2>&1
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/reactos_qcow2.sh" \
  "$TEST_SYS" "${TMP_DIR}/out.qcow2" >> "$LOG_PASS2" 2>&1

grep -q '\[SKIP\]' "$LOG_PASS2"
(cd "$TEST_SYS" && find . -type f | LC_ALL=C sort) > "$SNAP2"
cmp -s "$SNAP1" "$SNAP2"
printf '[PASS]     2-pass idempotency & all 6 export formats verified.\n'

# Negative Test 1: PE architecture mismatch rejection (x86_64 PE on i686 & i686 PE on x86_64)
PE32="${TMP_DIR}/pe32.exe"
PE64="${TMP_DIR}/pe64.exe"
printf 'MZ' > "$PE32"
dd if=/dev/zero bs=1 count=58 >> "$PE32" 2>/dev/null
printf '\100\000\000\000PE\000\000\114\001' >> "$PE32"

printf 'MZ' > "$PE64"
dd if=/dev/zero bs=1 count=58 >> "$PE64" 2>/dev/null
printf '\100\000\000\000PE\000\000\144\206' >> "$PE64"

if STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/pkg.sh" --check-pe "$PE64" i686 2>/dev/null; then
  printf '[FAIL] Expected x86_64 PE to be rejected on i686!\n' >&2
  exit 1
fi
if STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/reactos/pkg.sh" --check-pe "$PE32" x86_64 2>/dev/null; then
  printf '[FAIL] Expected i686 PE to be rejected on x86_64!\n' >&2
  exit 1
fi
printf '[PASS]     Bidirectional PE bitness guard (0x014c vs 0x8664) verified.\n'

# Negative Test 2: Solver rejects Linux-only systemd component on ReactOS
BAD_PROF="${TMP_DIR}/bad-reactos.json"
cat <<'BAD_EOF' > "$BAD_PROF"
{
  "schema_version": "1.0.0",
  "profile_name": "bad-reactos",
  "reactos_version": "0.4.16",
  "target": { "arch": "i686", "os_family": "reactos" },
  "init_system": { "provider": "nt-scm" },
  "storage": { "filesystem": "fat32", "bootloader": "freeldr" },
  "components": ["systemd"]
}
BAD_EOF
if STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/solver/resolve_stack.sh" "$BAD_PROF" >/dev/null 2>&1; then
  printf '[FAIL] Expected resolve_stack.sh to reject Linux-only systemd on ReactOS!\n' >&2
  exit 1
fi
printf '[PASS]     Dependency solver OS_UNSUPPORTED guard verified.\n'

printf '[OK]       ReactOS idempotency & guard matrix test PASSED.\n'
