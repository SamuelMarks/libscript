# Distributed Object, POSIX & Embedded Flash Filesystems (`_lib/storage-layers/`)

## Overview

**Tier Scope**: `T1 / T2`

S3-compatible object stores, distributed filesystems, FUSE cloud mounts, ZFS userland, and
microcontroller flash filesystems (`minio`, `garage`, `seaweedfs`, `ceph`, `glusterfs`, `juicefs`,
`gcsfuse`, `zfs`, `littlefs`).

Each subdirectory in `_lib/storage-layers/` is an atomic, self-contained LibScript component
governed by its own `manifest.json` and `vars.schema.json`. Components in `_lib/storage-layers/`
never cross-source sibling components directly; instead, they source `T0` helpers from
`engine/common/` and are composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5`
(`workloads/`), and `Plane A` (`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh ceph --help
./libscript.sh install ceph latest
./_lib/storage-layers/ceph/cli.sh test
```

```cmd
.\libscript.cmd ceph --help
.\libscript.cmd install ceph latest
.\_lib\storage-layers\ceph\cli.cmd test
```

## Components (9)

<!-- BEGIN_COMPONENTS -->

- [`ceph`](./ceph/README.md) (`T1` — `userland-package`, `service-daemon`): Unified distributed
  storage cluster providing RADOS object, RBD block, and CephFS file storage.
- [`garage`](./garage/README.md) (`T1` — `userland-package`, `service-daemon`): Lightweight
  geo-distributed S3-compatible object storage service designed for self-hosting.
- [`gcsfuse`](./gcsfuse/README.md) (`T1` — `userland-package`): Cloud Storage FUSE allows you to
  mount Cloud Storage buckets as file systems on Linux or macOS systems.
- [`glusterfs`](./glusterfs/README.md) (`T1` — `userland-package`, `service-daemon`): Scalable
  distributed network filesystem aggregating disk storage resources into a unified namespace.
- [`juicefs`](./juicefs/README.md) (`T1` — `userland-package`, `service-daemon`): High-performance
  cloud-native POSIX distributed filesystem built on top of object storage and metadata engines.
- [`littlefs`](./littlefs/README.md) (`T2` — `sysroot-package`, `sysroot-library`): Power-loss
  resilient wear-leveling NOR/NAND flash filesystem C library for Zephyr and FreeRTOS appliances.
- [`minio`](./minio/README.md) (`T1` — `userland-package`, `service-daemon`): High Performance
  Object Storage, API compatible with Amazon S3 cloud storage service.
- [`seaweedfs`](./seaweedfs/README.md) (`T1` — `userland-package`, `service-daemon`): Fast
  distributed blob storage, Filer POSIX filesystem, and S3-compatible object store with O(1) disk
  seek.
- [`zfs`](./zfs/README.md) (`T1` — `userland-package`): OpenZFS copy-on-write enterprise filesystem
  and logical volume administration utilities (zfs and zpool).

<!-- END_COMPONENTS -->
