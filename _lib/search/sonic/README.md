# Sonic (`_lib/search/sonic/`)

## Overview

Fast, lightweight, and schema-less search backend written in Rust as a minimal alternative to heavy
search clusters.

- **Tier**: `T1` (`_lib/search/sonic/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `sonic`, `search`

## Usage

```sh
# Install and manage the sonic service daemon
./libscript.sh install sonic latest
./libscript.sh start sonic
./libscript.sh status sonic
./libscript.sh logs sonic
./libscript.sh stop sonic
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install sonic latest
.\libscript.cmd start sonic
.\libscript.cmd status sonic
.\libscript.cmd stop sonic
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/sonic/<version>`
  (default `~/.libscript/sonic/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SONIC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SONIC_INSTALL_METHOD` | How to install sonic. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SONIC_VERSION`        | Specific version of sonic to install.                                                                                                          | `latest`           | latest, lts      |
| `SONIC_DOWNLOAD_URL`   | Override URL for downloading sonic binary or archive artifacts.                                                                                | `none`             |                  |
| `SONIC_RELEASES_URL`   | Override URL for querying sonic available remote releases.                                                                                     | `none`             |                  |
| `SONIC_LISTEN_PORT`    | TCP port on which the sonic service listens.                                                                                                   | `1491`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
