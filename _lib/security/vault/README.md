# HashiCorp Vault (`_lib/security/vault/`)

## Overview

Identity-based secrets management, dynamic credentials, and encryption-as-a-service server.

- **Tier**: `T1` (`_lib/security/vault/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `vault`, `secrets-manager`

## Usage

```sh
# Install and manage the vault service daemon
./libscript.sh install vault latest
./libscript.sh start vault
./libscript.sh status vault
./libscript.sh logs vault
./libscript.sh stop vault
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install vault latest
.\libscript.cmd start vault
.\libscript.cmd status vault
.\libscript.cmd stop vault
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/vault/<version>`
  (default `~/.libscript/vault/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `VAULT_INSTALL_METHOD` (or global
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

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `VAULT_INSTALL_METHOD` | How to install vault. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `VAULT_VERSION`        | Specific version of vault to install.                                                                                                          | `latest`           | latest, lts      |
| `VAULT_DOWNLOAD_URL`   | Override URL for downloading vault binary or archive artifacts.                                                                                | `none`             |                  |
| `VAULT_RELEASES_URL`   | Override URL for querying vault available remote releases.                                                                                     | `none`             |                  |
| `VAULT_LISTEN_PORT`    | TCP port on which the vault service listens.                                                                                                   | `8200`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
