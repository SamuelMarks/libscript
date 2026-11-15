#!/bin/sh
# ## Overview
# Deterministic FreeRTOSConfig.h synthesizer from declarative os-config.json or environment parameters.
# ## Usage
# ./_lib/kernel/freertos/gen_freertos_config.sh <out_dir> [os_config_json]

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

OUT_DIR="${1:-}"
OS_CFG="${2:-}"
if [ -z "$OUT_DIR" ]; then
  printf '[ERROR] Usage: gen_freertos_config.sh <out_dir> [os_config_json]\n' >&2
  exit 1
fi
mkdir -p "$OUT_DIR"

PORT="${FREERTOS_PORT:-${LIBSCRIPT_RTOS_BOARD:-mps2_an385}}"
HEAP_IMPL="${FREERTOS_HEAP_IMPL:-heap_4}"
TICK_HZ="${FREERTOS_TICK_RATE_HZ:-1000}"
HEAP_BYTES="${FREERTOS_TOTAL_HEAP_BYTES:-32768}"
MAX_PRIO="${FREERTOS_MAX_PRIORITIES:-8}"
MIN_STACK="${FREERTOS_MINIMAL_STACK_WORDS:-128}"
PREEMPT="${FREERTOS_USE_PREEMPTION:-1}"
TICKLESS="${FREERTOS_USE_TICKLESS_IDLE:-0}"
CORES="${FREERTOS_NUMBER_OF_CORES:-1}"
MPU="${FREERTOS_ENABLE_MPU:-0}"

if [ -n "$OS_CFG" ] && [ -f "$OS_CFG" ] && command -v jq >/dev/null 2>&1; then
  PORT=$(jq -r --arg d "$PORT" '.rtos.board // $d' "$OS_CFG")
  HEAP_IMPL=$(jq -r --arg d "$HEAP_IMPL" '.rtos.heap_implementation // $d' "$OS_CFG")
  TICK_HZ=$(jq -r --arg d "$TICK_HZ" '(.rtos.tick_rate_hz // $d) | tostring' "$OS_CFG")
  HEAP_BYTES=$(jq -r --arg d "$HEAP_BYTES" '(.rtos.total_heap_bytes // $d) | tostring' "$OS_CFG")
  MAX_PRIO=$(jq -r --arg d "$MAX_PRIO" '(.rtos.max_priorities // $d) | tostring' "$OS_CFG")
  MIN_STACK=$(jq -r --arg d "$MIN_STACK" '(.rtos.minimal_stack_words // $d) | tostring' "$OS_CFG")
fi

STATIC_ALLOC=1
DYN_ALLOC=1
if [ "$HEAP_IMPL" = "static_only" ]; then
  DYN_ALLOC=0
  HEAP_BYTES=0
fi

HDR="${OUT_DIR}/FreeRTOSConfig.h"
cat <<CFG > "${HDR}.tmp"
/* Auto-generated deterministically by LibScript gen_freertos_config.sh */
#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

#define configRTOS_PORT_NAME                    "${PORT}"
#define configRTOS_HEAP_IMPL                    "${HEAP_IMPL}"
#define configUSE_PREEMPTION                    ${PREEMPT}
#define configUSE_TICKLESS_IDLE                 ${TICKLESS}
#define configNUMBER_OF_CORES                   ${CORES}
#define configCPU_CLOCK_HZ                      ( 25000000UL )
#define configTICK_RATE_HZ                      ( ( uint32_t ) ${TICK_HZ} )
#define configMAX_PRIORITIES                    ( ${MAX_PRIO} )
#define configMINIMAL_STACK_SIZE                ( ( uint16_t ) ${MIN_STACK} )
#define configTOTAL_HEAP_SIZE                   ( ( size_t ) ( ${HEAP_BYTES} ) )
#define configMAX_TASK_NAME_LEN                 ( 16 )
#define configUSE_16_BIT_TICKS                  0
#define configIDLE_SHOULD_YIELD                 1
#define configSUPPORT_STATIC_ALLOCATION         ${STATIC_ALLOC}
#define configSUPPORT_DYNAMIC_ALLOCATION        ${DYN_ALLOC}
#define configUSE_MUTEXES                       1
#define configUSE_RECURSIVE_MUTEXES             1
#define configUSE_COUNTING_SEMAPHORES           1
#define configUSE_QUEUE_SETS                    1
#define configUSE_TIMERS                        1
#define configTIMER_TASK_PRIORITY               ( ${MAX_PRIO} - 1 )
#define configTIMER_QUEUE_LENGTH                10
#define configTIMER_TASK_STACK_DEPTH            ( ${MIN_STACK} * 2 )
#define configUSE_STREAM_BUFFERS                1
#define configUSE_MESSAGE_BUFFERS               1
#define configCHECK_FOR_STACK_OVERFLOW          2
#define configENABLE_MPU                        ${MPU}
#define configUSE_IDLE_HOOK                     0
#define configUSE_TICK_HOOK                     0
#define configUSE_MALLOC_FAILED_HOOK            0

#endif /* FREERTOS_CONFIG_H */
CFG
mv "${HDR}.tmp" "$HDR"
printf '%s\n' "$HEAP_IMPL" > "${OUT_DIR}/heap_selection.txt"
exit 0
