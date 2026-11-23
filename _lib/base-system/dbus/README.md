# D-Bus Message Bus (`_lib/base-system/dbus/`)

## Overview

Freedesktop D-Bus inter-process communication message bus daemon (dbus-daemon) and CLI tools.

- **Tier**: `T2` (`_lib/base-system/dbus/`)
- **Capabilities**: `sysroot-package`
- **Provides Virtual Capabilities**: `dbus`, `dbus-daemon`, `dbus-send`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `freebsd`, `openbsd`, `netbsd`, `sunos`,
  `macos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Stage into an isolated T3 target sysroot or install on a compatible host
LIBSCRIPT_TARGET_SYSROOT=/mnt/sysroot ./libscript.sh install dbus latest
./libscript.sh dbus --help
./_lib/base-system/dbus/cli.sh test
```

```cmd
:: Query component CLI or invoke test/Option-A boundary check on Windows
.\libscript.cmd dbus --help
.\_lib\base-system\dbus\cli.cmd test
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `DBUS_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `DBUS_INSTALL_METHOD` | How to install dbus. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `DBUS_VERSION`        | Specific version of dbus to install.                                                                                                          | `latest`           | latest, stable   |
| `DBUS_DOWNLOAD_URL`   | Override URL for downloading dbus binary or archive artifacts.                                                                                | `none`             |                  |
| `DBUS_RELEASES_URL`   | Override URL for querying dbus available remote releases.                                                                                     | `none`             |                  |
| `DBUS_LISTEN_PORT`    | TCP port on which the dbus service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
