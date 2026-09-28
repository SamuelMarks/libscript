# S6 / S6-rc

## Purpose & Overview

Provides the Skarnet S6 process supervision suite and S6-rc dependency manager, compiling service
databases and managing `s6-svscan` PID 1 execution.

## Usage

```sh
# Configure S6/S6-rc inside the target rootfs
./_lib/init-systems/s6/setup.sh install /path/to/rootfs

# Check installation status
./_lib/init-systems/s6/setup.sh status
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
