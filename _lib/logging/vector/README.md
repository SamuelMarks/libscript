# Vector (`_lib/logging/vector/`)

## Overview

High-performance end-to-end observability data router and transformation pipeline built in Rust.

- **Tier**: `T1` (`_lib/logging/vector/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `vector`, `log-shipper`, `observability`

## Usage

```sh
# Install and manage the vector service daemon
./libscript.sh install vector latest
./libscript.sh start vector
./libscript.sh status vector
./libscript.sh logs vector
./libscript.sh stop vector
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install vector latest
.\libscript.cmd start vector
.\libscript.cmd status vector
.\libscript.cmd stop vector
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/vector/<version>`
  (default `~/.libscript/vector/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `VECTOR_INSTALL_METHOD` (or global
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

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `VECTOR_INSTALL_METHOD` | How to install vector. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `VECTOR_VERSION`        | Specific version of vector to install.                                                                                                          | `latest`           | latest, lts      |
| `VECTOR_DOWNLOAD_URL`   | Override URL for downloading vector binary or archive artifacts.                                                                                | `none`             |                  |
| `VECTOR_RELEASES_URL`   | Override URL for querying vector available remote releases.                                                                                     | `none`             |                  |
| `VECTOR_LISTEN_PORT`    | TCP port on which the vector service listens.                                                                                                   | `8686`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
