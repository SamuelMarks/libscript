#!/bin/sh
# ## Overview
# Unit and 2x-idempotency test suite for `tests/register_bento_boxes.sh` DOS `.box` discovery and registration.
# ## Usage
# ./tests/test_register_bento_boxes.sh

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

TEST_WORK=$(mktemp -d "${TMPDIR:-/tmp}/ls_reg_bento.XXXXXX")
trap 'rm -rf "$TEST_WORK" 2>/dev/null || true' EXIT INT TERM

# ## fail_test
# Prints an error message to stderr and exits with code 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

MOCK_BENTO="${TEST_WORK}/bento"
MOCK_BIN="${TEST_WORK}/bin"
MOCK_VAG_HOME="${TEST_WORK}/vagrant_home"
MOCK_STATE="${TEST_WORK}/vagrant_boxes.txt"
MOCK_ADDS="${TEST_WORK}/vagrant_adds.log"

mkdir -p \
  "${MOCK_BIN}" \
  "${MOCK_VAG_HOME}/boxes" \
  "${MOCK_BENTO}/builds/build_complete" \
  "${MOCK_BENTO}/os_pkrvars/omnios" \
  "${MOCK_BENTO}/os_pkrvars/alpine" \
  "${MOCK_BENTO}/os_pkrvars/debian" \
  "${MOCK_BENTO}/os_pkrvars/rockylinux" \
  "${MOCK_BENTO}/os_pkrvars/freebsd" \
  "${MOCK_BENTO}/os_pkrvars/macos" \
  "${MOCK_BENTO}/os_pkrvars/windows" \
  "${MOCK_BENTO}/os_pkrvars/freedos" \
  "${MOCK_BENTO}/os_pkrvars/msdos"

: > "${MOCK_STATE}"
: > "${MOCK_ADDS}"

for _a in aarch64 x86_64; do
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/alpine/alpine-3.24-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/debian/debian-13-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/rockylinux/rockylinux-10-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/freebsd/freebsd-15-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/windows/windows-11-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/freedos/freedos-1.3-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/freedos/freedos-1.4-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/msdos/msdos-1.25-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/msdos/msdos-2.0-${_a}.pkrvars.hcl"
  printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/msdos/msdos-4.0-${_a}.pkrvars.hcl"
done
printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/omnios/omnios-braich-aarch64.pkrvars.hcl"
printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/macos/macos-14-aarch64.pkrvars.hcl"
printf '%s\n' '# pkrvars' > "${MOCK_BENTO}/os_pkrvars/macos/macos-27-aarch64.pkrvars.hcl"
for _b in freedos-builder.sh freedos-builder.cmd msdos-builder.sh msdos-builder.cmd; do
  printf '%s\n' '# builder' > "${MOCK_BENTO}/${_b}"
done

for _box in \
  msdos-1.25-aarch64.qemu.box \
  msdos-2.0-aarch64.qemu.box \
  msdos-4.0-x86_64.qemu.box \
  freedos-1.3-aarch64.qemu.box; do
  printf '%s\n' 'MOCK-BOX' > "${MOCK_BENTO}/builds/build_complete/${_box}"
done

cat <<MOCK_VAGRANT > "${MOCK_BIN}/vagrant"
#!/bin/sh
set -eu
if [ "\${1:-}" = "box" ] && [ "\${2:-}" = "list" ]; then
  cat "${MOCK_STATE}"
  exit 0
fi
if [ "\${1:-}" = "box" ] && [ "\${2:-}" = "add" ]; then
  shift 2
  _name=""
  _prov="qemu"
  while [ \$# -gt 0 ]; do
    case "\$1" in
      --name) _name="\$2"; shift 2 ;;
      --provider) _prov="\$2"; shift 2 ;;
      --force) shift ;;
      *) _file="\$1"; shift ;;
    esac
  done
  printf '%s (%s, 0)\n' "\$_name" "\$_prov" >> "${MOCK_STATE}"
  printf '%s|%s|%s\n' "\$_name" "\$_prov" "\$_file" >> "${MOCK_ADDS}"
  _vs=\$(printf '%s' "\$_name" | sed 's|/|-VAGRANTSLASH-|g')
  mkdir -p "${MOCK_VAG_HOME}/boxes/\${_vs}/0/arm64/qemu"
  exit 0
fi
exit 0
MOCK_VAGRANT
chmod +x "${MOCK_BIN}/vagrant"

# 1. Verify --validate-only checks DOS pkrvars and standalone builders without invoking vagrant box add
VAL_OUT=$(PATH="${MOCK_BIN}:${PATH}" VAGRANT_HOME="${MOCK_VAG_HOME}" STACK="" \
  "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" --bento-dir "${MOCK_BENTO}" --arch aarch64 --validate-only 2>&1)
printf '%s\n' "$VAL_OUT" | grep -q 'os_pkrvars/freedos/freedos-1.3-aarch64.pkrvars.hcl' || fail_test 'Missing FreeDOS 1.3 pkrvars validation'
printf '%s\n' "$VAL_OUT" | grep -q 'os_pkrvars/msdos/msdos-4.0-aarch64.pkrvars.hcl' || fail_test 'Missing MS-DOS 4.0 pkrvars validation'
printf '%s\n' "$VAL_OUT" | grep -q 'msdos-builder.sh' || fail_test 'Missing msdos-builder.sh validation'
[ ! -s "${MOCK_ADDS}" ] || fail_test '--validate-only must not register any boxes'

# 2. First registration run: registers canonical bento/* + legacy anondos/* + cross-arch fallback (msdos-4.0-x86_64)
PATH="${MOCK_BIN}:${PATH}" VAGRANT_HOME="${MOCK_VAG_HOME}" STACK="" \
  "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" --bento-dir "${MOCK_BENTO}" --arch aarch64 >/dev/null 2>&1

for _expected in \
  'bento/msdos-1.25|qemu' \
  'bento/msdos-2.0|qemu' \
  'bento/msdos-4.0|qemu' \
  'bento/freedos-1.3|qemu' \
  'bento/freedos|qemu' \
  'anondos/msdos-1.25|qemu' \
  'anondos/msdos-2.0|qemu' \
  'anondos/msdos-4.0|qemu' \
  'anondos/freedos-1.3|qemu' \
  'anondos/freedos-1.4|qemu'; do
  grep -q "^${_expected}|" "${MOCK_ADDS}" || fail_test "Expected registration for ${_expected}"
done

[ -L "${MOCK_VAG_HOME}/boxes/bento-VAGRANTSLASH-msdos-4.0/0/arm64/libvirt" ] || fail_test 'Expected arm64/libvirt -> arm64/qemu symlink'

ADD_COUNT_1=$(wc -l < "${MOCK_ADDS}" | tr -d ' ')

# 3. Second registration run (2x idempotency): zero additional vagrant box add calls
RUN2_OUT=$(PATH="${MOCK_BIN}:${PATH}" VAGRANT_HOME="${MOCK_VAG_HOME}" STACK="" \
  "${LIBSCRIPT_ROOT_DIR}/tests/register_bento_boxes.sh" --bento-dir "${MOCK_BENTO}" --arch aarch64 2>&1)
ADD_COUNT_2=$(wc -l < "${MOCK_ADDS}" | tr -d ' ')
[ "$ADD_COUNT_1" = "$ADD_COUNT_2" ] || fail_test "Idempotency violation: add count grew from ${ADD_COUNT_1} to ${ADD_COUNT_2}"
printf '%s\n' "$RUN2_OUT" | grep -q '\[OK\]   Box bento/msdos-4.0 (qemu) is already registered' || fail_test 'Expected already-registered message on 2nd run'

printf '%s\n' '[PASS] register_bento_boxes.sh DOS discovery, cross-arch fallback, and 2x idempotency tests passed.'
exit 0
