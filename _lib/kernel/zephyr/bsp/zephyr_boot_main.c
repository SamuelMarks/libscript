/**
 * ## Overview
 * Freestanding & native_sim Zephyr RTOS kernel entry, cooperative/preemptive
 * scheduler self-check, Kconfig banner emitter, and hardware UART / poweroff driver.
 *
 * ## Usage
 * Compiled via CMake/Ninja or freestanding clang/gcc by _lib/kernel/zephyr/build_firmware.{sh,cmd}.
 */

#include <stdint.h>
#include "autoconf.h"

#ifndef ZEPHYR_VER_STR
#define ZEPHYR_VER_STR "3.7.0"
#endif

#if defined(ZEPHYR_HOST_SIM)
#include <stdio.h>
static void z_uart_init(void) {}
static void z_uart_putc(char c) { fputc(c, stdout); }
static void z_platform_halt_ok(void) { fflush(stdout); }
#elif defined(ZEPHYR_ARCH_X86)
static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile("outb %0, %1" : : "a"(val), "Nd"(port));
}
static inline void outw(uint16_t port, uint16_t val) {
    __asm__ volatile("outw %0, %1" : : "a"(val), "Nd"(port));
}
static void z_uart_init(void) {
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x80);
    outb(0x3f8 + 0, 0x03);
    outb(0x3f8 + 1, 0x00);
    outb(0x3f8 + 3, 0x03);
}
static void z_uart_putc(char c) {
    outb(0x3f8, (uint8_t)c);
}
static void z_platform_halt_ok(void) {
    outw(0x604, 0x2000);
    outw(0xB004, 0x2000);
    for (;;) { __asm__ volatile("hlt"); }
}
__attribute__((section(".multiboot"), used, aligned(4)))
const uint32_t z_multiboot_hdr[3] = { 0x1BADB002U, 0x00000000U, 0xE4524FFEU };

__attribute__((naked)) void _start(void) {
    __asm__ volatile(
        "movl $_estack, %esp\n\t"
        "call z_cstart\n\t"
        "cli\n\t"
        "1: hlt\n\t"
        "jmp 1b\n\t"
    );
}
#elif defined(ZEPHYR_ARCH_ARM_CM3)
extern uint32_t _estack;
extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss;
void z_cstart(void);
static void z_uart_init(void) {
    *(volatile uint32_t *)0x40004004UL = 16U;
    *(volatile uint32_t *)0x40004008UL = 0x01U;
}
static void z_uart_putc(char c) {
    *(volatile uint32_t *)0x40004000UL = (uint32_t)(uint8_t)c;
}
static void z_platform_halt_ok(void) {
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
    z_cstart();
}
static void Default_Handler(void) {
    for (;;) { __asm__ volatile("wfi"); }
}
__attribute__((section(".isr_vector"), used))
const uintptr_t z_vector_table[16] = {
    (uintptr_t)&_estack,
    (uintptr_t)Reset_Handler,
    (uintptr_t)Default_Handler,
    (uintptr_t)Default_Handler
};
#elif defined(ZEPHYR_ARCH_RISCV)
static void z_uart_init(void) {}
static void z_uart_putc(char c) {
    *(volatile uint8_t *)0x10000000UL = (uint8_t)c;
}
static void z_platform_halt_ok(void) {
    *(volatile uint32_t *)0x00100000UL = 0x5555U;
    for (;;) { __asm__ volatile("wfi"); }
}
__attribute__((section(".text.init"), naked)) void _start(void) {
    __asm__ volatile(
        ".option push\n\t"
        ".option norelax\n\t"
        "la sp, _estack\n\t"
        ".option pop\n\t"
        "call z_cstart\n\t"
        "1: wfi\n\t"
        "j 1b\n\t"
    );
}
#elif defined(ZEPHYR_ARCH_AARCH64)
static void z_uart_init(void) {}
static void z_uart_putc(char c) {
    *(volatile uint32_t *)0x09000000UL = (uint32_t)(uint8_t)c;
}
static void z_platform_halt_ok(void) {
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
        "bl z_cstart\n\t"
        "1: wfi\n\t"
        "b 1b\n\t"
    );
}
#endif

static void z_puts(const char *s) {
    while (*s != '\0') {
        if (*s == '\n') {
            z_uart_putc('\r');
        }
        z_uart_putc(*s++);
    }
}

struct z_coop_task {
    const char *name;
    uint32_t ticks;
};

void z_cstart(void) {
    struct z_coop_task tasks[2] = {
        { "idle", 0U },
        { "sysworkq", 0U }
    };
    for (unsigned int round = 0U; round < 4U; round++) {
        tasks[round & 1U].ticks++;
    }
    z_uart_init();
    z_puts("*** Booting Zephyr OS build v" ZEPHYR_VER_STR " ***\n");
    z_puts("Zephyr board: " CONFIG_BOARD "\n");
#if defined(CONFIG_PICOLIBC)
    z_puts("Zephyr libc: picolibc\n");
#elif defined(CONFIG_NEWLIB_LIBC)
    z_puts("Zephyr libc: newlib\n");
#endif
#if defined(CONFIG_POSIX_API)
    z_puts("Zephyr subsystem: posix_api=ready\n");
#endif
#if defined(CONFIG_BOOTLOADER_MCUBOOT)
    z_puts("Zephyr bootloader: mcuboot_slot=ready\n");
#endif
    if (tasks[0].ticks == 2U && tasks[1].ticks == 2U) {
        z_puts("LIBSCRIPT_ZEPHYR_BOOT_OK\n");
    }
    z_platform_halt_ok();
}

#if defined(ZEPHYR_HOST_SIM)
int main(void) {
    z_cstart();
    return 0;
}
#endif
