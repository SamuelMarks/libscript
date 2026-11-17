#!/bin/sh
# ## Overview
# Test suite for Bento Builder stack, verifying hypervisor tools, `BENTO_DIR` & `RUBYLIB`
# idempotent resolution, `Bento::VagrantMsdos` / `Bento::VagrantFreedos` plugin presence, and
# idempotent DOS box build/register routing.
#
# ## Usage
# ./_lib/virtualization/bento-builder/test.sh

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

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${PATH:-}"

# ## fail_bento_test
# Prints an error message and exits with status 1.
fail_bento_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

printf '%s\n' '=== Checking Hypervisors & Tools ==='

printf '%s\n' '--- QEMU ---'
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
  qemu-system-x86_64 --version | head -n 1
elif command -v qemu-system-aarch64 >/dev/null 2>&1; then
  qemu-system-aarch64 --version | head -n 1
elif command -v qemu-system-i386 >/dev/null 2>&1; then
  qemu-system-i386 --version | head -n 1
elif command -v qemu-img >/dev/null 2>&1; then
  qemu-img --version | head -n 1
else
  printf '%s\n' 'qemu not found (optional in container test environments).' >&2
fi

printf '%s\n' '--- Packer & Vagrant ---'
if command -v packer >/dev/null 2>&1; then
  packer --version | head -n 1
fi
if command -v vagrant >/dev/null 2>&1; then
  vagrant --version | head -n 1
fi
if command -v ruby >/dev/null 2>&1; then
  ruby -v
fi

printf '%s\n' '=== Verifying 2x Idempotent env.sh & DOS Builder Routing ==='
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ls_bento_bld.XXXXXX")
trap 'rm -rf "$TEST_TMP" 2>/dev/null || true' EXIT INT TERM

MOCK_BENTO="${TEST_TMP}/bento"
mkdir -p "${MOCK_BENTO}/lib/bento" "${MOCK_BENTO}/builds/build_complete" "${MOCK_BENTO}/os_pkrvars/msdos" "${MOCK_BENTO}/os_pkrvars/freedos"
printf '%s\n' '# mock gemspec' > "${MOCK_BENTO}/bento.gemspec"
printf '%s\n' '# msdos plugin' > "${MOCK_BENTO}/lib/bento/vagrant_msdos.rb"
printf '%s\n' '# freedos plugin' > "${MOCK_BENTO}/lib/bento/vagrant_freedos.rb"
printf '%s\n' 'MOCK-BOX' > "${MOCK_BENTO}/builds/build_complete/msdos-4.0-aarch64.qemu.box"

ORIG_BENTO_DIR="${BENTO_DIR:-}"
BENTO_DIR="${MOCK_BENTO}" \
RUBYLIB="" \
STACK="" \
sh -c '
  set -feu
  SCRIPT_NAME="$1/env.sh"
  export SCRIPT_NAME
  . "$SCRIPT_NAME"
  unset SCRIPT_NAME || true
  r1="${RUBYLIB:-}"
  STACK=""
  export STACK
  SCRIPT_NAME="$1/env.sh"
  export SCRIPT_NAME
  . "$SCRIPT_NAME"
  unset SCRIPT_NAME || true
  r2="${RUBYLIB:-}"
  [ -n "$r1" ] && [ "$r1" = "$r2" ]
' sh "${SCRIPT_DIR}" || fail_bento_test 'env.sh failed 2x RUBYLIB idempotency check'

MOCK_BIN="${TEST_TMP}/bin"
mkdir -p "${MOCK_BIN}"
cat <<'MOCK_VAG' > "${MOCK_BIN}/vagrant"
#!/bin/sh
exit 0
MOCK_VAG
chmod +x "${MOCK_BIN}/vagrant"

BUILD_OUT=$(PATH="${MOCK_BIN}:${PATH}" STACK="" "${SCRIPT_DIR}/cli.sh" build msdos-4.0 --bento-dir="${MOCK_BENTO}" 2>&1)
printf '%s\n' "$BUILD_OUT" | grep -q '\[SKIP\] msdos-4.0 box already built' || fail_bento_test 'Expected idempotent skip when msdos-4.0 box already exists'

bento_dir=""
for candidate in "${ORIG_BENTO_DIR}" "${LIBSCRIPT_ROOT_DIR}/../bento" "$HOME/bento"; do
  if [ -n "$candidate" ] && [ -f "$candidate/bento.gemspec" ]; then
    bento_dir="$candidate"
    break
  fi
done

if [ -n "$bento_dir" ]; then
  printf '%s\n' "=== Validating Real Bento Repository at $bento_dir ==="
  [ -f "$bento_dir/lib/bento/vagrant_msdos.rb" ] || fail_bento_test "Missing $bento_dir/lib/bento/vagrant_msdos.rb"
  [ -f "$bento_dir/lib/bento/vagrant_freedos.rb" ] || fail_bento_test "Missing $bento_dir/lib/bento/vagrant_freedos.rb"
  [ -f "$bento_dir/msdos-builder.sh" ] || fail_bento_test "Missing $bento_dir/msdos-builder.sh"
  [ -f "$bento_dir/freedos-builder.sh" ] || fail_bento_test "Missing $bento_dir/freedos-builder.sh"
fi

printf '%s\n' '=== All Bento Builder checks completed successfully! ==='
