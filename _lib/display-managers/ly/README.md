# Ly TUI Display Manager (`_lib/display-managers/ly/`)

## Overview

Lightweight ncurses-like terminal user interface (TUI) display manager for Linux and BSD supporting
Wayland and X11.

- **Tier**: `T2` (`_lib/display-managers/ly/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `ly`, `display-manager`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`
- **Target OS Exclusions (`manifest.json`)**: `windows`, `macos`

## Usage

```sh
# Install and manage the ly service daemon
./libscript.sh install ly latest
./libscript.sh start ly
./libscript.sh status ly
./libscript.sh logs ly
./libscript.sh stop ly
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install ly latest
.\libscript.cmd start ly
.\libscript.cmd status ly
.\libscript.cmd stop ly
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `LY_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable            | Description                                                                                                                                 | Default            | Aliases/Examples |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `LY_INSTALL_METHOD` | How to install ly. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LY_VERSION`        | Specific version of ly to install.                                                                                                          | `latest`           | latest, stable   |
| `LY_DOWNLOAD_URL`   | Override URL for downloading ly binary or archive artifacts.                                                                                | `none`             |                  |
| `LY_RELEASES_URL`   | Override URL for querying ly available remote releases.                                                                                     | `none`             |                  |
| `LY_LISTEN_PORT`    | TCP port on which the ly service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
