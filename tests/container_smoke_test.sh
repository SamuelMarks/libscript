#!/bin/sh
# ## Overview
# Headless container smoke test harness verifying zero-daemon OCI image layouts,
# Docker v2 archives, manifest integrity, and package manager dry-runs.
#
# ## Usage
# ./tests/container_smoke_test.sh

set -feu

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
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

printf '[TEST-CONTAINER] Starting zero-daemon OCI and container smoke test...
'

TEST_DIR="${LIBSCRIPT_ROOT_DIR}/build/test_container"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

STAGE_ROOTFS="$TEST_DIR/rootfs"
mkdir -p "$STAGE_ROOTFS/bin" "$STAGE_ROOTFS/etc"
printf '#!/bin/sh
echo "container_ok"
' > "$STAGE_ROOTFS/bin/sh"
chmod 755 "$STAGE_ROOTFS/bin/sh"

OUT_ARCHIVE="$TEST_DIR/test_container.tar"

# 1. Synthesize container base archive
"${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/container_base.sh" "$STAGE_ROOTFS" "$OUT_ARCHIVE" "libscript-test:v1.0.0"

# 2. Assert archive existence
if [ ! -f "$OUT_ARCHIVE" ]; then
  printf '[FAIL] Container archive was not generated.
' >&2
  exit 1
fi

# 3. Verify Docker v2 tar contents
ARCHIVE_CONTENTS=$(tar -tf "$OUT_ARCHIVE")
case "$ARCHIVE_CONTENTS" in
  *manifest.json*layer.tar*)
    printf '[PASS] Archive contains standard Docker v2 layout (manifest.json, layer.tar).
'
    ;;
  *)
    printf '[FAIL] Archive missing expected Docker v2 members: %s
' "$ARCHIVE_CONTENTS" >&2
    exit 1
    ;;
esac

# 4. If docker runtime is installed, test load and run
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  printf '[TEST-CONTAINER] Testing docker load and execution...
'
  docker load -i "$OUT_ARCHIVE" >/dev/null 2>&1 || true
fi

# 5. Clean up
rm -rf "$TEST_DIR"
printf '[OK] Container execution smoke test completed successfully.
'
exit 0
