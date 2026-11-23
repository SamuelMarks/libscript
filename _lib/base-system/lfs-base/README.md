# LFS Base

**Tier**: `T2` (`_lib/base-system/lfs-base/`) | **Capabilities**: `sysroot-package`

Stage 3 Linux From Scratch (LFS) base system installation and filesystem hierarchy configuration.

## Overview

Constructs the standard FHS 3.0 filesystem hierarchy, configures essential system files
(`/etc/passwd`, `/etc/group`, `/etc/fstab`, `/etc/os-release`, locale, and networking defaults), and
deploys foundational packages within the LFS target rootfs.

## Usage

```sh
./_lib/base-system/lfs-base/setup.sh [install|clean|status] [--hostname=lfs-node]
```

On Windows environments, native execution terminates with status 86 (`EX_UNAVAILABLE`) and defers to
container or Vagrant VM builders:

```cmd
call _lib\base-system\lfs-base\setup.cmd [install|clean|status]
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                  | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `LFS_BASE_VERSION`        | Specific version of LFS Base System to synthesize.                                                           | `latest`           |                  |
| `LFS_BASE_INSTALL_METHOD` | How to install LFS_BASE. 'libscript_native' uses isolated sysroot staging, 'system' uses OS package manager. | `libscript_native` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
