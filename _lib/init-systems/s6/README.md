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

| Variable            | Description                                         | Default  | Aliases/Examples |
| ------------------- | --------------------------------------------------- | -------- | ---------------- |
| `S6_VERSION`        | Specific version of s6 to install.                  | `latest` |                  |
| `S6_INSTALL_METHOD` | How to install S6 ('libscript_native' or 'system'). | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
