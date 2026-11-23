# NVIDIA Triton Inference Server (`_lib/app-servers/triton/`)

## Overview

Open-source inference serving software streamlining AI model deployment across GPUs and CPUs.

- **Tier**: `T1` (`_lib/app-servers/triton/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `triton`, `inference-server`, `app-server`
- **Target OS Exclusions (`manifest.json`)**: `darwin`, `freebsd`, `sunos`

## Usage

```sh
# Install and manage the triton service daemon
./libscript.sh install triton latest
./libscript.sh start triton
./libscript.sh status triton
./libscript.sh logs triton
./libscript.sh stop triton
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install triton latest
.\libscript.cmd start triton
.\libscript.cmd status triton
.\libscript.cmd stop triton
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/triton/<version>`
  (default `~/.libscript/triton/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TRITON_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `backup_tenant.{sh,cmd}`,
`configure.{sh,cmd}`, `deprovision_tenant.{sh,cmd}`, `log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`,
`metrics.{sh,cmd}`, `probe.{sh,cmd}`, `provision_tenant.{sh,cmd}`, `restore.{sh,cmd}`,
`restore_tenant.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TRITON_INSTALL_METHOD` | How to install triton. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TRITON_VERSION`        | Specific version of triton to install.                                                                                                          | `latest`           | latest, lts      |
| `TRITON_DOWNLOAD_URL`   | Override URL for downloading triton binary or archive artifacts.                                                                                | `none`             |                  |
| `TRITON_RELEASES_URL`   | Override URL for querying triton available remote releases.                                                                                     | `none`             |                  |
| `TRITON_LISTEN_PORT`    | TCP port on which the triton service listens.                                                                                                   | `8000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
