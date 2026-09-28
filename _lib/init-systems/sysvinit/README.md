# SysVinit

## Purpose & Overview

Provides the classical System V Init (SysVinit) PID 1 supervisor, `/etc/inittab` runlevel
configuration (runlevels 0-6), and SysV service control scripts for Linux From Scratch appliances.

## Usage

```sh
# Configure SysVinit inside the target rootfs
./_lib/init-systems/sysvinit/setup.sh install /path/to/rootfs

# Check installation status
./_lib/init-systems/sysvinit/setup.sh status
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
