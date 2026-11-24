# Tier 3 (`T3`) Universal Package & Image Format Drivers (`synthesis/formats/`)

## Overview

`synthesis/formats/` implements the format-specific artifact compilers dispatched by
`./libscript.sh package-as <format>` (`synthesis/cli.{sh,cmd}`). Each driver consumes resolved
`T1`/`T2` components or `T3` sysroots and emits deterministic native installers, containers, virtual
machine disks, cloud boot images, unikernels, or microcontroller firmware binaries.

See [`../../PACKAGING_BRANDING_GUIDE.md`](../../PACKAGING_BRANDING_GUIDE.md) and
[`freebsd_distro.md`](./freebsd_distro.md) for cross-format branding rules and FreeBSD image
specifics.

## Format Drivers

- **Native OS Packages & Installers**:
  - `msi.{sh,cmd}` (WiX / `msi-rs` Windows `.msi`, backed by `synthesis/msi/`), `inno.{sh,cmd}`
    (Inno Setup `.exe`), `nsis.{sh,cmd}` (NSIS `.exe`)
  - `deb.{sh,cmd}` & `build_deb.{sh,cmd}` (Debian/Ubuntu `.deb`)
  - `rpm.{sh,cmd}` & `build_rpm.{sh,cmd}` (Fedora/RHEL/Rocky `.rpm`)
  - `apk.{sh,cmd}` & `build_apk.{sh,cmd}` (Alpine `.apk`)
  - `txz.{sh,cmd}` (FreeBSD / illumos `.txz`), `pkg.{sh,cmd}` & `dmg.{sh,cmd}` (macOS)
  - `tui_installer.{sh,cmd}` (self-extracting interactive TUI installer)
- **Containers & Rootfs Tarballs**:
  - `docker.{sh,cmd}`, `docker_archive.{sh,cmd}`, `docker_compose.{sh,cmd}`, `oci_image.{sh,cmd}`,
    `rootfs_tar.{sh,cmd}`
- **Virtual Machine, Live ISO & Cloud Disk Images**:
  - `disk_builder.{sh,cmd}`, `raw_img.{sh,cmd}`, `qcow2.{sh,cmd}`, `vmdk.{sh,cmd}`, `vdi.{sh,cmd}`,
    `hyperv_vhd.{sh,cmd}`, `iso.{sh,cmd}`, `vagrant_box.{sh,cmd}`, `proxmox_tpl.{sh,cmd}`
  - `cloud_img.{sh,cmd}`, `aws_ami.{sh,cmd}`, `azure_vhd.{sh,cmd}`, `gcp_image.{sh,cmd}`
- **Linux, BSD, illumos, ReactOS, Unikernel & RTOS Targets**:
  - `linux_distro.{sh,cmd}` (`linux-distro` & `linux-kernel`: glibc/musl/LFS distros & direct-boot
    Linux `bzImage` + `initramfs` / UKI bundles)
  - `bsd_img.{sh,cmd}`, `freebsd_distro.{sh,cmd}`, `freebsd_iso.{sh,cmd}`, `freebsd_qcow2.{sh,cmd}`,
    `freebsd_raw.{sh,cmd}`, `freebsd_vagrant_box.{sh,cmd}`
  - `illumos_distro.{sh,cmd}`, `reactos_distro.{sh,cmd}`
  - `unikernel_img.{sh,cmd}` & `direct_kernel.{sh,cmd}` (`unikernel-distro` / `unikernel`: OSv,
    Nanos, MirageOS, Unikraft, Rumprun, UEFI-GPT & Azure Gen2 VHD cloud-boot unikernels)
  - `rtos_distro.{sh,cmd}` & `firmware_bin.{sh,cmd}` (`rtos-distro` / `firmware-bin`: Zephyr &
    FreeRTOS `.bin`, `.elf`, `.hex`, `.uf2`, MCUboot-signed images, Renode `.resc`)
  - `_profile_dispatch.{sh,cmd}` (automatic `target.os_family` profile router for `qcow2`,
    `raw-img`, `iso`, and `direct-kernel`)

## Usage

```sh
./libscript.sh package-as deb --stack workloads/apps/wordpress/packaging.json
./libscript.sh package-as linux-distro --profile synthesis/profiles/linux/linux-minimal-headless-musl.json --format qcow2
./libscript.sh package-as linux-kernel --profile synthesis/profiles/linux/linux-kernel-gcc-tiny.json --format direct-kernel
./libscript.sh package-as unikernel-distro --profile synthesis/profiles/unikernel/osv-cloud-runtime.json --format elf
./libscript.sh package-as rtos-distro --profile synthesis/profiles/rtos/zephyr-cortex-m3-mcuboot-signed.json --format firmware-bin
```
