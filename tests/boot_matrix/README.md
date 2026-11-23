# Automated Multi-Profile QEMU Boot Matrix (`tests/boot_matrix/`)

## Overview

`tests/boot_matrix/` (`run_boot_smoke.{sh,cmd}`) iterates across synthesized `T3` Linux, FreeBSD,
illumos, ReactOS, unikernel, and RTOS profiles under headless QEMU/KVM/HVF acceleration, asserting
serial console kernel banners, init supervision readiness, and zero panic/fault markers within
bounded timeouts.

## Usage

```sh
./tests/boot_matrix/run_boot_smoke.sh
```
