# containerd Container Runtime (`_lib/containers/containerd/`)

## Overview

Industry-standard CNCF graduated core container runtime daemon (containerd, ctr,
containerd-shim-runc-v2).

- **Tier**: `T1` (`_lib/containers/containerd/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `containerd`, `ctr`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `windows`, `freebsd`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/containerd/<version>)
./libscript.sh ls-remote containerd
./libscript.sh install containerd latest
./libscript.sh use containerd latest
./libscript.sh which containerd
./_lib/containers/containerd/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote containerd
.\libscript.cmd install containerd latest
.\libscript.cmd use containerd latest
.\libscript.cmd which containerd
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/containerd/<version>`
  (default `~/.libscript/containerd/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `CONTAINERD_INSTALL_METHOD` (or global
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

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CONTAINERD_INSTALL_METHOD` | How to install containerd. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CONTAINERD_VERSION`        | Specific version of containerd to install.                                                                                                          | `latest`           | latest, stable   |
| `CONTAINERD_DOWNLOAD_URL`   | Override URL for downloading containerd binary or archive artifacts.                                                                                | `none`             |                  |
| `CONTAINERD_RELEASES_URL`   | Override URL for querying containerd available remote releases.                                                                                     | `none`             |                  |
| `CONTAINERD_LISTEN_PORT`    | TCP port on which the containerd service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
