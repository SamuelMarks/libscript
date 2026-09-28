# Dinit

## Purpose & Overview

Provides the modern dependency-based Dinit service supervisor, declarative service descriptor
configurations (`/etc/dinit.d/`), and lightweight PID 1 execution.

## Usage

```sh
# Configure Dinit inside the target rootfs
./_lib/init-systems/dinit/setup.sh install /path/to/rootfs

# Check installation status
./_lib/init-systems/dinit/setup.sh status
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
