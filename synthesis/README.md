# Tier 3 (`T3`): Image, OS & Artifact Synthesis (`synthesis/`)

## Overview

`synthesis/` compiles atomic `T1`/`T2` recipes (`_lib/`) and offline `Plane A` traits (`traits/`)
into immutable OS images, unikernels, MCU firmware, and native installers:

- `synthesis/profiles/`: Declarative OS, unikernel, RTOS, hypervisor, and cloud profiles grouped by
  target family (`linux/`, `lfs/`, `freebsd/`, `illumos/`, `reactos/`, `unikernel/`, `rtos/`,
  `cloud/`, `hypervisor/`, `containers/`).
- `synthesis/schemas/`: `synthesis/schemas/os-config.schema.json` and `execution-plan*.schema.json`.
- `synthesis/vfs/` & `synthesis/disk/`: Target sysroot FHS staging, VFS/chroot runners, disk
  discovery, partitioning, LUKS encryption, and filesystem formatting.
- `synthesis/distro/` & `synthesis/repogen/`: Linux, FreeBSD, illumos, ReactOS, unikernel, RTOS, and
  Bento distro assemblers plus native package repository generators.
- `synthesis/formats/` & `synthesis/msi/`: Unified `package-as` format drivers (`.msi`, `.deb`,
  `.rpm`, `.apk`, `.txz`, `.dmg`, `.pkg`, `inno`, `nsis`, `qcow2`, `iso`, `raw_img`, `oci_image`,
  `unikernel_img`, `firmware_bin`) and Modular MSI synthesis infrastructure.
