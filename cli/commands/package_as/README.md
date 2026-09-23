# LibScript System Packaging Commands (`package-as`)

## Overview

Provides commands to package target sysroot filesystems into bootable images, containers, and
virtual machine disk appliances.

## Available Target Formats

- `raw_img`: Packages a target sysroot into a partitioned, bootable raw disk image (`.img`).
- `qcow2`: Packages a target sysroot into a QEMU Copy-On-Write (`.qcow2`) virtual disk image.
- `vdi`: Packages a target sysroot into a VirtualBox Virtual Disk Image (`.vdi`).
- `vmdk`: Packages a target sysroot into a VMware Virtual Machine Disk (`.vmdk`).
- `live_iso`: Synthesizes an El Torito / EFI hybrid bootable Live ISO image.
- `docker`: Builds an OCI/Docker container image directly from target sysroot rootfs.
- `tarball`: Archives target sysroot into a compressed distribution tarball.

## Usage

```sh
# Generate a bootable raw disk image
./libscript.sh package-as raw_img /target/sysroot /output/disk.img 20G uefi

# Generate a qcow2 VM disk
./libscript.sh package-as qcow2 /target/sysroot /output/disk.qcow2 20G uefi
```
