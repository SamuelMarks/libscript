# SysVinit

**Tier**: `T2` (`_lib/init-systems/sysvinit/`) | **Capabilities**: `sysroot-package`,
`service-daemon`

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

| Variable                  | Description                                               | Default  | Aliases/Examples |
| ------------------------- | --------------------------------------------------------- | -------- | ---------------- |
| `SYSVINIT_VERSION`        | Specific version of sysvinit to install.                  | `latest` |                  |
| `SYSVINIT_INSTALL_METHOD` | How to install SYSVINIT ('libscript_native' or 'system'). | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
