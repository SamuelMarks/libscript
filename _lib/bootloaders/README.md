# UEFI, BIOS, U-Boot & MCU Bootloaders (`_lib/bootloaders/`)

## Overview

**Tier Scope**: `T2`

System bootloaders and boot managers spanning x86_64/ARM64/RISC-V servers and desktops (`grub`,
`systemd-boot`, `limine`, `refind`, `u-boot`) and signed microcontroller firmware (`mcuboot`).

Each subdirectory in `_lib/bootloaders/` is an atomic, self-contained LibScript component governed
by its own `manifest.json` and `vars.schema.json`. Components in `_lib/bootloaders/` never
cross-source sibling components directly; instead, they source `T0` helpers from `engine/common/`
and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and
`Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh grub --help
./libscript.sh install grub latest
./_lib/bootloaders/grub/cli.sh test
```

```cmd
.\libscript.cmd grub --help
.\libscript.cmd install grub latest
.\_lib\bootloaders\grub\cli.cmd test
```

## Components (5)

<!-- BEGIN_COMPONENTS -->

- [`grub`](./grub/README.md) (`T2` — `sysroot-package`, `bootloader`): Standalone GNU GRand Unified
  Bootloader v2 (grub-install, grub-mkconfig, grub-mkstandalone) for BIOS and UEFI systems.
- [`limine`](./limine/README.md) (`T2` — `sysroot-package`, `bootloader`): Modern, portable,
  multiprotocol UEFI and BIOS bootloader supporting Linux, Limine boot protocol, multiboot2, and
  chainloading.
- [`mcuboot`](./mcuboot/README.md) (`T2` — `sysroot-package`, `bootloader`): Cryptographic A/B
  dual-slot microcontroller and RTOS bootloader with imgtool RSA/ECDSA/Ed25519 firmware signing.
- [`refind`](./refind/README.md) (`T2` — `sysroot-package`, `bootloader`): Graphical UEFI boot
  manager and automatic EFI OS/kernel discovery tool (refind-install).
- [`systemd-boot`](./systemd-boot/README.md) (`T2` — `sysroot-package`, `bootloader`): UEFI boot
  manager (bootctl and systemd-bootx64.efi / systemd-bootaa64.efi) supporting Type #1 Boot Loader
  Specification entries and Type #2 UKIs.

<!-- END_COMPONENTS -->
