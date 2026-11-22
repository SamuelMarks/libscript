# Runit

## Purpose & Overview

Provides the lightweight Runit service supervisor suite, three-stage boot orchestration
(`/etc/runit/1`, `/etc/runit/2`, `/etc/runit/3`), and `/etc/service` supervision directories.

## Usage

```sh
# Configure Runit inside the target rootfs
./_lib/init-systems/runit/setup.sh install /path/to/rootfs

# Check installation status
./_lib/init-systems/runit/setup.sh status
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                            | Default  | Aliases/Examples |
| ---------------------- | ------------------------------------------------------ | -------- | ---------------- |
| `RUNIT_VERSION`        | Specific version of runit to install.                  | `latest` |                  |
| `RUNIT_INSTALL_METHOD` | How to install RUNIT ('libscript_native' or 'system'). | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
