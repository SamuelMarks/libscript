# Keycloak (`_lib/security/keycloak/`)

## Overview

Open-source Identity and Access Management server supporting OpenID Connect, OAuth 2.0, and SAML
2.0.

- **Tier**: `T1` (`_lib/security/keycloak/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `keycloak`, `iam`, `oidc`, `saml`

## Usage

```sh
# Install and manage the keycloak service daemon
./libscript.sh install keycloak latest
./libscript.sh start keycloak
./libscript.sh status keycloak
./libscript.sh logs keycloak
./libscript.sh stop keycloak
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install keycloak latest
.\libscript.cmd start keycloak
.\libscript.cmd status keycloak
.\libscript.cmd stop keycloak
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/keycloak/<version>`
  (default `~/.libscript/keycloak/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `KEYCLOAK_INSTALL_METHOD` (or global
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

| Variable                  | Description                                                                                                                                       | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `KEYCLOAK_INSTALL_METHOD` | How to install keycloak. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `KEYCLOAK_VERSION`        | Specific version of keycloak to install.                                                                                                          | `latest`           | latest, lts      |
| `KEYCLOAK_DOWNLOAD_URL`   | Override URL for downloading keycloak binary or archive artifacts.                                                                                | `none`             |                  |
| `KEYCLOAK_RELEASES_URL`   | Override URL for querying keycloak available remote releases.                                                                                     | `none`             |                  |
| `KEYCLOAK_LISTEN_PORT`    | TCP port on which the keycloak service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
