# Unicorn (`_lib/app-servers/unicorn/`)

## Overview

Rack HTTP server for fast clients and Unix-like operating systems utilizing pre-forking worker
processes.

- **Tier**: `T1` (`_lib/app-servers/unicorn/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `unicorn`, `rack-server`, `app-server`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the unicorn service daemon
./libscript.sh install unicorn latest
./libscript.sh start unicorn
./libscript.sh status unicorn
./libscript.sh logs unicorn
./libscript.sh stop unicorn
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install unicorn latest
.\libscript.cmd start unicorn
.\libscript.cmd status unicorn
.\libscript.cmd stop unicorn
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/unicorn/<version>`
  (default `~/.libscript/unicorn/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `UNICORN_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `UNICORN_INSTALL_METHOD` | How to install unicorn. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `UNICORN_VERSION`        | Specific version of unicorn to install.                                                                                                          | `latest`           | latest, lts      |
| `UNICORN_DOWNLOAD_URL`   | Override URL for downloading unicorn binary or archive artifacts.                                                                                | `none`             |                  |
| `UNICORN_RELEASES_URL`   | Override URL for querying unicorn available remote releases.                                                                                     | `none`             |                  |
| `UNICORN_LISTEN_PORT`    | TCP port on which the unicorn service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
