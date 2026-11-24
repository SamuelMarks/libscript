# Tier 3 (`T3`) OS Distribution Synthesizers (`synthesis/distro/`)

## Overview

`synthesis/distro/` houses the operating system distribution builders and stage orchestrators that
compile `T1`/`T2` atomic `_lib/` recipes, `Plane A` offline sysroot traits, and
`synthesis/profiles/` execution plans into complete bootable Linux, FreeBSD, illumos, ReactOS,
Unikernel, and Bento VM systems.

## Submodules & Stage Scripts

- [`linux/`](./linux/README.md): Modular Linux distribution builder (Alpine-style, Debian-style, Red
  Hat-style, and custom LFS/musl/glibc sysroots).
- [`freebsd/`](./freebsd/README.md) & `freebsd-base/`: FreeBSD 15.x kernel/world synthesis,
  ZFS-on-root staging, pluggable init systems (`bsd-rc`, `openrc`, `runit`, `s6`, `dinit`), and
  Wayland/X11 desktops.
- [`illumos/`](./illumos/README.md): illumos / OmniOS ZFS boot-environment (`beadm`), SMF, `pkgsrc`,
  and desktop/server appliance synthesis.
- [`reactos/`](./reactos/README.md) & `reactos-base/`: Hybrid upstream BootCD/LiveCD ISO repacking
  (`unattend.inf` + `firstboot.cmd`) and RosBE CMake/Ninja source synthesis (`i686` & `x86_64`).
- [`bento/`](./bento/README.md): Automated Packer/QEMU multi-OS Vagrant base-box synthesis wrapper.
- **Composable Stage Scripts (`*_stage.{sh,cmd}`)**: `kernel_stage`, `init_stage`,
  `bootloader_stage`, `networking_stage`, `graphics_stage`, `display_servers_stage`,
  `display_managers_stage`, `desktops_stage`, `audio_stage`, `grub_multiboot`,
  `postgres_unikernel_build`, `redis_unikernel_build`, and `synthesize-image`.

## Usage

```sh
./libscript.sh package-as linux-distro --profile synthesis/profiles/linux/linux-minimal-headless-musl.json --format qcow2
./libscript.sh package-as freebsd-distro --profile synthesis/profiles/freebsd/freebsd-server-standard.json --format qcow2
./libscript.sh package-as illumos-distro --profile synthesis/profiles/illumos/minimal-server.json --format qcow2
./libscript.sh package-as reactos-distro --profile synthesis/profiles/reactos/desktop-classic-i686.json --format qcow2
./libscript.sh package-as unikernel-distro --profile synthesis/profiles/unikernel/osv-cloud-runtime.json --format elf
./libscript.sh package-as rtos-distro --profile synthesis/profiles/rtos/zephyr-cortex-m3-mcuboot-signed.json --format firmware-bin
```
