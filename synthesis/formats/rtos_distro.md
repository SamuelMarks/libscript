# RTOS Kernel & Microcontroller Firmware Packaging (`rtos-distro`)

## Overview

`synthesis/formats/rtos_distro.{sh,cmd}` provides the unified `package-as` driver for deterministic
**Zephyr** (`rtos-zephyr`) and **FreeRTOS** (`rtos-freertos`) profiles across ARM Cortex-M, RISC-V,
Xtensa, and QEMU/Renode/POSIX simulators.

## Usage

```sh
./libscript.sh package-as rtos-distro --profile zephyr-rtos.json --format firmware-bin
./libscript.sh package-as rtos-distro --profile freertos.json --format firmware-elf
./libscript.sh package-as rtos-distro --profile rtos/zephyr-cortex-m3-mcuboot-signed --format mcuboot-signed
```

```cmd
.\libscript.cmd package-as rtos-distro --profile zephyr-rtos.json --format firmware-bin
.\libscript.cmd package-as rtos-distro --profile freertos.json --format firmware-elf
```
