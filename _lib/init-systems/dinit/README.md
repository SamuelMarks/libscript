# Dinit

**Tier**: `T2` (`_lib/init-systems/dinit/`) | **Capabilities**: `sysroot-package`, `service-daemon`

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

| Variable               | Description                                            | Default  | Aliases/Examples |
| ---------------------- | ------------------------------------------------------ | -------- | ---------------- |
| `DINIT_VERSION`        | Specific version of dinit to install.                  | `latest` |                  |
| `DINIT_INSTALL_METHOD` | How to install DINIT ('libscript_native' or 'system'). | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
