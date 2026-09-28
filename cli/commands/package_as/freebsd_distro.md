# FreeBSD Distribution Packaging & Export (`freebsd_distro`)

## Overview

The `freebsd_distro` command provides unified packaging and disk image exporting for FreeBSD
distribution profiles synthesized by LibScript.

Supported export formats:

- **`raw`**: Sparse raw GPT disk image (`freebsd_raw.sh` / `.cmd`).
- **`qcow2`**: Compressed, sparse QEMU copy-on-write image (`freebsd_qcow2.sh` / `.cmd`).
- **`box`**: Redistributable Vagrant box archive containing `metadata.json`, `Vagrantfile`, and disk
  image (`freebsd_vagrant_box.sh` / `.cmd`).
- **`vhd`**: Microsoft Hyper-V dynamic disk image (`freebsd_vhd.sh` / `.cmd`).
- **`vmdk`**: VMware Workstation / ESXi stream-optimized image (`freebsd_vmdk.sh` / `.cmd`).
- **`iso`**: Hybrid UEFI / BIOS bootable installation ISO (`freebsd_iso.sh` / `.cmd`).

## Usage

Packaging via POSIX shell:

```sh
./cli/commands/package_as/freebsd_distro.sh --format qcow2 --profile profiles/freebsd/minimal-server.json --output build/freebsd.qcow2
./cli/commands/package_as/freebsd_distro.sh --format box --profile profiles/freebsd/zfs-cloud.json --output build/freebsd.box
```

Packaging via Windows Command Prompt:

```cmd
.\cli\commands\package_as\freebsd_distro.cmd --format qcow2 --profile profiles\freebsd\minimal-server.json --output build\freebsd.qcow2
.\cli\commands\package_as\freebsd_distro.cmd --format box --profile profiles\freebsd\zfs-cloud.json --output build\freebsd.box
```
