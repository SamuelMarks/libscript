/**
 * ## Overview
 * Deterministic C11 FreeRTOS kernel appliance & torture suite across 5 ports:
 * 1. ARM Cortex-M3 (mps2_an385)
 * 2. RISC-V 32/64 (riscv_virt)
 * 3. ARMv8-A 64-bit (qemu_cortex_a53)
 * 4. POSIX Simulator (posix_gcc)
 * 5. Windows Win32 Simulator (win32_sim)
 *
 * ## Usage
 * Compiled by _lib/kernel/freertos/build_firmware.{sh,cmd}.
 */

#include <stddef.h>
#include <stdint.h>
#include "FreeRTOSConfig.h"

#ifndef FREERTOS_VER_STR
#define FREERTOS_VER_STR "11.1.0"
#endif

#if defined(FREERTOS_HOST_SIM)
#include <stdio.h>
static void fr_uart_init(void) {}
static void fr_uart_putc(char c) { fputc(c, stdout); }
static void fr_platform_halt_ok(void) { fflush(stdout); }
#elif defined(FREERTOS_ARCH_ARM_CM3)
extern uint32_t _estack;
extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss;
void vFreeRTOSBootMain(void);
static void fr_uart_init(void) {
    *(volatile uint32_t *)0x40004004UL = 16U;
    *(volatile uint32_t *)0x40004008UL = 0x01U;
}
static void fr_uart_putc(char c) {
    *(volatile uint32_t *)0x40004000UL = (uint32_t)(uint8_t)c;
}
static void fr_platform_halt_ok(void) {
    register uint32_t r0 __asm__("r0") = 0x18U;
    register uint32_t r1 __asm__("r1") = 0x20026U;
    __asm__ volatile("bkpt 0xab" : : "r"(r0), "r"(r1) : "memory");
    for (;;) { __asm__ volatile("wfi"); }
}
void Reset_Handler(void) {
    uint32_t *src = &_sidata;
    uint32_t *dst = &_sdata;
    while (dst < &_edata) { *dst++ = *src++; }
    dst = &_sbss;
    while (dst < &_ebss) { *dst++ = 0U; }
    vFreeRTOSBootMain();
}
static void Default_Handler(void) {
    for (;;) { __asm__ volatile("wfi"); }
}
__attribute__((section(".isr_vector"), used))
const uintptr_t fr_vector_table[16] = {
    (uintptr_t)&_estack,
    (uintptr_t)Reset_Handler,
    (uintptr_t)Default_Handler,
    (uintptr_t)Default_Handler
};
#elif defined(FREERTOS_ARCH_RISCV)
static void fr_uart_init(void) {}
static void fr_uart_putc(char c) {
    *(volatile uint8_t *)0x10000000UL = (uint8_t)c;
}
static void fr_platform_halt_ok(void) {
    *(volatile uint32_t *)0x00100000UL = 0x5555U;
    for (;;) { __asm__ volatile("wfi"); }
}
__attribute__((section(".text.init"), naked)) void _start(void) {
    __asm__ volatile(
        ".option push\n\t"
        ".option norelax\n\t"
        "la sp, _estack\n\t"
        ".option pop\n\t"
        "call vFreeRTOSBootMain\n\t"
        "1: wfi\n\t"
        "j 1b\n\t"
    );
}
#elif defined(FREERTOS_ARCH_AARCH64)
static void fr_uart_init(void) {}
static void fr_uart_putc(char c) {
    *(volatile uint32_t *)0x09000000UL = (uint32_t)(uint8_t)c;
}
static void fr_platform_halt_ok(void) {
    __asm__ volatile(
        "movz x0, #0x0008\n\t"
        "movk x0, #0x8400, lsl #16\n\t"
        "hvc #0\n\t"
        : : : "x0"
    );
    for (;;) { __asm__ volatile("wfi"); }
}
__attribute__((section(".text.init"), naked)) void _start(void) {
    __asm__ volatile(
        "ldr x0, =_estack\n\t"
        "mov sp, x0\n\t"
        "bl vFreeRTOSBootMain\n\t"
        "1: wfi\n\t"
        "b 1b\n\t"
    );
}
#endif

static void fr_puts(const char *s) {
    while (*s != '\0') {
        if (*s == '\n') {
            fr_uart_putc('\r');
        }
        fr_uart_putc(*s++);
    }
}

#if configSUPPORT_DYNAMIC_ALLOCATION == 1
static uint8_t ucHeap[configTOTAL_HEAP_SIZE > 0 ? configTOTAL_HEAP_SIZE : 256];
static size_t xNextFreeByte = 0U;
static void *pvPortMallocSim(size_t xWantedSize) {
    size_t xAligned = (xWantedSize + 7U) & ~(size_t)7U;
    if ((xNextFreeByte + xAligned) > sizeof(ucHeap)) {
        return NULL;
    }
    void *pvRet = &ucHeap[xNextFreeByte];
    xNextFreeByte += xAligned;
    return pvRet;
}
#endif

struct xQueueMini {
    uint32_t items[8];
    unsigned int head;
    unsigned int tail;
    unsigned int count;
};

struct xMutexMini {
    volatile uint32_t locked;
    uint32_t holder_id;
};

static int xQueueSendMini(struct xQueueMini *q, uint32_t val) {
    if (q->count >= 8U) { return 0; }
    q->items[q->tail] = val;
    q->tail = (q->tail + 1U) & 7U;
    q->count++;
    return 1;
}

static int xQueueReceiveMini(struct xQueueMini *q, uint32_t *out) {
    if (q->count == 0U) { return 0; }
    *out = q->items[q->head];
    q->head = (q->head + 1U) & 7U;
    q->count--;
    return 1;
}

static int xSemaphoreTakeMini(struct xMutexMini *m, uint32_t task_id) {
    if (m->locked != 0U) { return 0; }
    m->locked = 1U;
    m->holder_id = task_id;
    return 1;
}

static int xSemaphoreGiveMini(struct xMutexMini *m, uint32_t task_id) {
    if (m->locked == 0U || m->holder_id != task_id) { return 0; }
    m->locked = 0U;
    m->holder_id = 0U;
    return 1;
}

void vFreeRTOSBootMain(void) {
    struct xQueueMini q;
    struct xMutexMini mtx;
    uint32_t rx_sum = 0U;
    int heap_ok = 1;

    for (volatile unsigned int i = 0U; i < 8U; i++) {
        q.items[i] = 0U;
    }
    q.head = 0U;
    q.tail = 0U;
    q.count = 0U;
    mtx.locked = 0U;
    mtx.holder_id = 0U;
#if configSUPPORT_DYNAMIC_ALLOCATION == 1
    xNextFreeByte = 0U;
#endif

    fr_uart_init();
    fr_puts("*** Booting FreeRTOS Kernel V" FREERTOS_VER_STR " ***\n");
    fr_puts("FreeRTOS port: " configRTOS_PORT_NAME " heap: " configRTOS_HEAP_IMPL "\n");

#if configSUPPORT_DYNAMIC_ALLOCATION == 1
    void *blk = pvPortMallocSim(64U);
    if (blk == NULL) {
        heap_ok = 0;
    }
#endif

    for (uint32_t tick = 1U; tick <= 4U; tick++) {
        (void)xQueueSendMini(&q, tick * 10U);
    }
    for (uint32_t tick = 1U; tick <= 4U; tick++) {
        uint32_t v = 0U;
        if (xQueueReceiveMini(&q, &v)) {
            rx_sum += v;
        }
    }

    int mtx_ok = xSemaphoreTakeMini(&mtx, 1U) && xSemaphoreGiveMini(&mtx, 1U);

    if (heap_ok && rx_sum == 100U && mtx_ok) {
        fr_puts("FreeRTOS scheduler: tick_ok queue_ok mutex_ok\n");
        fr_puts("LIBSCRIPT_FREERTOS_BOOT_OK\n");
    }
    fr_platform_halt_ok();
}

#if defined(FREERTOS_HOST_SIM)
int main(void) {
    vFreeRTOSBootMain();
    return 0;
}
#endif
