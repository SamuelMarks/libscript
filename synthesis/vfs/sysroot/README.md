# Tier 3 (`T3`) Sysroot Virtual Filesystem Lifecycle (`synthesis/vfs/sysroot/`)

## Overview

`synthesis/vfs/sysroot/` manages idempotent mounting (`mount_target_vfs.{sh,cmd}`) and reverse-order
unmounting (`umount_target_vfs.{sh,cmd}`) of virtual kernel filesystems (`/proc`, `/sys`, `/dev`,
`/dev/pts`, `/dev/shm`, `/run`, and FreeBSD `devfs`) inside `LIBSCRIPT_TARGET_SYSROOT` during `T3`
OS synthesis. Signal traps ensure host pseudo-filesystems are cleanly detached even on interrupted
builds.

## Usage

```sh
./synthesis/vfs/sysroot/mount_target_vfs.sh /mnt/sysroot
./synthesis/vfs/sysroot/umount_target_vfs.sh /mnt/sysroot
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                          | Default  |
| :------------------- | :--------------------------------------------------------------------------------------------------- | :------- |
| `VFS_VERSION`        | Specific version of vfs to install.                                                                  | `latest` |
| `VFS_INSTALL_METHOD` | How to install VFS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
