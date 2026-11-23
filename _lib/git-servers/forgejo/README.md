# Forgejo (`_lib/git-servers/forgejo/`)

## Overview

Self-hosted lightweight community-governed software forge supporting Git, CI/CD Actions, and
packages.

- **Tier**: `T1` (`_lib/git-servers/forgejo/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `forgejo`, `git-server`

## Usage

```sh
# Install and manage the forgejo service daemon
./libscript.sh install forgejo latest
./libscript.sh start forgejo
./libscript.sh status forgejo
./libscript.sh logs forgejo
./libscript.sh stop forgejo
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install forgejo latest
.\libscript.cmd start forgejo
.\libscript.cmd status forgejo
.\libscript.cmd stop forgejo
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/forgejo/<version>`
  (default `~/.libscript/forgejo/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `FORGEJO_INSTALL_METHOD` (or global
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
| `FORGEJO_INSTALL_METHOD` | How to install forgejo. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FORGEJO_VERSION`        | Specific version of forgejo to install.                                                                                                          | `latest`           | latest, lts      |
| `FORGEJO_DOWNLOAD_URL`   | Override URL for downloading forgejo binary or archive artifacts.                                                                                | `none`             |                  |
| `FORGEJO_RELEASES_URL`   | Override URL for querying forgejo available remote releases.                                                                                     | `none`             |                  |
| `FORGEJO_LISTEN_PORT`    | TCP port on which the forgejo service listens.                                                                                                   | `3000`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
