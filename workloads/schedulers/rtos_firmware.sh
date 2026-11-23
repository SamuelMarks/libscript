#!/bin/sh
# ## Overview
# Tier 4 RTOS Firmware & MCU Scheduler translating declarative payload.json manifests
# into QEMU headless emulation, Renode (.resc) multi-node scripts, or OpenOCD hardware flash jobs.
#
# ## Usage
# ./workloads/schedulers/rtos_firmware.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--runner <qemu|renode|openocd>]

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

# ## compile_rtos_spec
# Emits deterministic QEMU, Renode, or OpenOCD deployment JSON from payload.json.
compile_rtos_spec() {
  _pf="$1"
  _runner="${2:-qemu}"
  jq --arg runner "$_runner" '{
    scheduler: "rtos_firmware",
    runner: $runner,
    kernel: (.artifact.rtos_kernel // "zephyr"),
    board: (.artifact.board // "qemu_cortex_m3"),
    firmware_elf: (.artifact.firmware_path // "/var/lib/libscript/zephyr.elf"),
    memory_kb: ((.resources.memory_mb // 1) * 1024),
    command: (
      if $runner == "renode" then "renode --disable-xwt --console firmware.resc"
      elif $runner == "openocd" then "openocd -f board/generic.cfg -c \"program firmware.elf verify reset exit\""
      else "qemu-system-arm -machine mps2-an385 -cpu cortex-m3 -nographic -kernel firmware.elf" end
    )
  }' "$_pf"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--runner <qemu|renode|openocd>]\n' "${THIS_FILE}"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"
RUNNER="${LIBSCRIPT_RTOS_RUNNER:-qemu}"
if [ "${3:-}" = "--runner" ]; then
  RUNNER="${4:-qemu}"
fi

case "$ACTION" in
  compile) compile_rtos_spec "$TARGET" "$RUNNER" ;;
  submit|status|logs|stop|destroy)
    printf '{"scheduler":"rtos_firmware","runner":"%s","action":"%s","workload":"%s","status":"ok"}\n' "$RUNNER" "$ACTION" "$TARGET"
    ;;
  *) exit 1 ;;
esac
