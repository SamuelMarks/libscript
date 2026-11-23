# Tier 3 (`T3`) Disk Partitioning, LUKS2 & Filesystem Synthesis (`synthesis/disk/`)

## Overview

`synthesis/disk/` provides block-device partitioning, UEFI/BIOS layout construction, optional LUKS2
(`argon2id`) full-disk encryption, multi-filesystem formatting, and target sysroot mounting for `T3`
operating system image synthesis and live bare-metal installation.

On Windows (`Win32`), kernel loop/mount operations follow the **Option A Hard-Fail Boundary
Proforma** (exit code `86`), delegating raw image synthesis to `engine/common/vm_builder.cmd`.

## Scripts

- **`partitioner.{sh,cmd}` & `partitionary.{sh,cmd}`**: Declarative GPT and MBR partition table
  engines (`sfdisk`, `sgdisk`, `gpart`, `parted`) creating EFI System Partitions (ESP), BIOS boot
  slices, swap, ZFS/Btrfs pools, and root partitions.
- **`format.{sh,cmd}`**: Formats target partitions across `ext4`, `btrfs` (with `@`, `@home`,
  `@snapshots` subvolumes), `xfs`, `vfat`/`fat32`, `zfs`, `ufs`, and `ntfs` (delegating shared
  primitives to `T0` `engine/common/format_fs.{sh,cmd}`).
- **`provision_disk.{sh,cmd}`**: End-to-end disk image allocator (`truncate`/`qemu-img`), loopback
  attacher, partitioner, LUKS2 formatter, and filesystem builder.
- **`mount_sysroot.{sh,cmd}`**: Mounts formatted partition hierarchies in topological path order
  under `LIBSCRIPT_TARGET_SYSROOT` and generates matching `/etc/fstab` or ZFS mountpoint properties.

## Usage

```sh
./synthesis/disk/provision_disk.sh --image build/os.raw --size 10G --fs btrfs
./synthesis/disk/mount_sysroot.sh --image build/os.raw --sysroot build/sysroot
```
