# illumos Distribution Packaging & Export (`illumos_distro`)

## Overview

The `illumos_distro` command provides unified packaging and disk image exporting for illumos distribution profiles synthesized by LibScript.

Supported export formats:
- **`raw`**: Sparse raw GPT / VTOC disk image with ZFS pool (`illumos_raw.sh` / `.cmd`).
- **`qcow2`**: Compressed, sparse QEMU copy-on-write image with lazy refcounts (`illumos_qcow2.sh` / `.cmd`).
- **`box`**: Redistributable Vagrant box archive containing `metadata.json`, `Vagrantfile` (Solaris/illumos guest), and disk image (`illumos_vagrant_box.sh` / `.cmd`).
- **`vhd`**: Microsoft Hyper-V dynamic disk image (`illumos_vhd.sh` / `.cmd`).
- **`vmdk`**: VMware Workstation / ESXi stream-optimized image (`illumos_vmdk.sh` / `.cmd`).
- **`iso`**: Bootable hybrid ISO installation image (`illumos_iso.sh` / `.cmd`).

## Usage

Packaging via POSIX shell:
```sh
./cli/commands/package_as/illumos_distro.sh --format qcow2 --profile profiles/illumos/minimal-server.json --output build/illumos.qcow2
./cli/commands/package_as/illumos_distro.sh --format box --profile profiles/illumos/zfs-cloud.json --output build/illumos.box
```

Packaging via Windows Command Prompt:
```cmd
.\cli\commands\package_as\illumos_distro.cmd --format qcow2 --profile profiles\illumos\minimal-server.json --output build\illumos.qcow2
.\cli\commands\package_as\illumos_distro.cmd --format box --profile profiles\illumos\zfs-cloud.json --output build\illumos.box
```
