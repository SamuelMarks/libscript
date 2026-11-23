# OS Kernels, Initramfs & Real-Time Operating Systems (`_lib/kernel/`)

## Overview

**Tier Scope**: `T2`

Linux kernel source/fragment builder (`linux`), CPIO/UKI `initramfs` generator (`initramfs`), and
embedded RTOS kernels (`zephyr`, `freertos`).

Each subdirectory in `_lib/kernel/` is an atomic, self-contained LibScript component governed by its
own `manifest.json` and `vars.schema.json`. Components in `_lib/kernel/` never cross-source sibling
components directly; instead, they source `T0` helpers from `engine/common/` and are composed upward
by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh freertos --help
./libscript.sh install freertos latest
./_lib/kernel/freertos/cli.sh test
```

```cmd
.\libscript.cmd freertos --help
.\libscript.cmd install freertos latest
.\_lib\kernel\freertos\cli.cmd test
```

## Components (4)

<!-- BEGIN_COMPONENTS -->

- [`freertos`](./freertos/README.md) (`T2` — `sysroot-package`, `kernel-image`): FreeRTOS C11
  real-time kernel source manager, FreeRTOSConfig.h synthesizer, and multi-architecture
  firmware/simulator builder.
- [`initramfs`](./initramfs/README.md) (`T2` — `sysroot-package`, `kernel-image`): Linux initial
  ramdisk generation utilities
- [`linux`](./linux/README.md) (`T2` — `sysroot-package`, `kernel-image`): Monolithic Unix operating
  system kernel
- [`zephyr`](./zephyr/README.md) (`T2` — `sysroot-package`, `kernel-image`): Zephyr Real-Time
  Operating System kernel source manager, Kconfig/Devicetree synthesizer, and multi-board firmware
  builder.

<!-- END_COMPONENTS -->
