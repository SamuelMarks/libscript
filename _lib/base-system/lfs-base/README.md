# LFS Base

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
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
