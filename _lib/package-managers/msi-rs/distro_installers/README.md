# msi-rs Distro Installers

## Purpose & Overview

Provides operating system deployment and co-installation orchestrators for the `msi-rs` live
installer pipeline. Supports native staging and dual-boot provisioning across Linux, FreeBSD, and
illumos targets.

## Usage

```sh
# Deploy Linux base system
./install_linux.sh <target_disk> <root_partition> [efi_partition]

# Deploy FreeBSD base system
./install_freebsd.sh <target_disk> <root_partition> [efi_partition]

# Deploy illumos base system
./install_illumos.sh <target_disk> <zpool_partition> [efi_partition]

# Concurrent Dual-OS deployment (Linux + FreeBSD)
./coinstall_dual_os.sh <disk_dev> <linux_part> <freebsd_part> [esp_part]

# Universal Multiboot deployment (Linux + FreeBSD + illumos)
./multiboot_orchestrator.sh <disk_dev> [options...]
```

## Available Scripts

- `install_linux.sh` / `.cmd`: Deploys Linux rootfs and bootloader configurations.
- `install_freebsd.sh` / `.cmd`: Deploys FreeBSD world, kernel, and loader configurations.
- `install_illumos.sh` / `.cmd`: Deploys illumos ZFS root environment.
- `coinstall_dual_os.sh` / `.cmd`: Concurrently stages Linux and FreeBSD with shared EFI and unified
  GRUB menu.
- `multiboot_orchestrator.sh` / `.cmd`: Concurrently stages Linux, FreeBSD, and illumos with master
  GRUB2 multiboot configuration.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
