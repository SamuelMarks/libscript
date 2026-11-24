# Linux Kernel & Distribution Packaging (`linux-distro` & `linux-kernel`)

## Overview

`synthesis/formats/linux_distro.{sh,cmd}` provides the unified `package-as` driver for Linux
distributions (`glibc`, `musl`, Alpine/Debian/Red Hat styles, and Linux From Scratch `lfs`) as well
as standalone custom-compiled Linux kernels (`bzImage`, `initramfs`, and `.efi` Unified Kernel
Images).

It implements the exact same `--profile` / `--format` / `--output` contract as `freebsd-distro`,
`illumos-distro`, `reactos-distro`, `unikernel-distro`, and `rtos-distro`.

## Usage

```sh
# Synthesize a bootable Linux QCOW2, ISO, or raw disk image from a profile
./libscript.sh package-as linux-distro --profile linux-os.json --format qcow2
./libscript.sh package-as linux-distro --profile linux/linux-debian-style-server --format iso

# Synthesize a direct-boot Linux kernel + initramfs bundle (QEMU / Firecracker / UKI)
./libscript.sh package-as linux-kernel --profile linux/linux-kernel-gcc-tiny --format direct-kernel

# Dry-run execution plan verification
./libscript.sh package-as linux-distro --profile linux-os.json --format qcow2 --dry-run
```

```cmd
.\libscript.cmd package-as linux-distro --profile linux-os.json --format qcow2
.\libscript.cmd package-as linux-kernel --profile linux/linux-kernel-gcc-tiny --format direct-kernel
```
