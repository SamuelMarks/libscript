# macOS/Darwin launchd Adapter (`_lib/init-systems/launchd/`)

## Overview

macOS and Darwin launchd Property List (plist) service manager adapter and launchctl lifecycle
bridge.

- **Tier**: `T2` (`_lib/init-systems/launchd/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `launchd`, `launchctl`
- **Target OS Whitelist (`manifest.json`)**: `macos`, `darwin`

## Usage

```sh
# Install and manage the launchd service daemon
./libscript.sh install launchd latest
./libscript.sh start launchd
./libscript.sh status launchd
./libscript.sh logs launchd
./libscript.sh stop launchd
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install launchd latest
.\libscript.cmd start launchd
.\libscript.cmd status launchd
.\libscript.cmd stop launchd
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `LAUNCHD_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `LAUNCHD_INSTALL_METHOD` | How to install launchd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `LAUNCHD_VERSION`        | Specific version of launchd to install.                                                                                                          | `latest`           | latest, stable   |
| `LAUNCHD_DOWNLOAD_URL`   | Override URL for downloading launchd binary or archive artifacts.                                                                                | `none`             |                  |
| `LAUNCHD_RELEASES_URL`   | Override URL for querying launchd available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
