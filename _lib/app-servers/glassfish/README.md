# Eclipse GlassFish (`_lib/app-servers/glassfish/`)

## Overview

Eclipse Foundation open-source Jakarta EE compatible enterprise application server.

- **Tier**: `T1` (`_lib/app-servers/glassfish/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `glassfish`, `jakarta-ee`, `app-server`

## Usage

```sh
# Install and manage the glassfish service daemon
./libscript.sh install glassfish latest
./libscript.sh start glassfish
./libscript.sh status glassfish
./libscript.sh logs glassfish
./libscript.sh stop glassfish
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install glassfish latest
.\libscript.cmd start glassfish
.\libscript.cmd status glassfish
.\libscript.cmd stop glassfish
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/glassfish/<version>`
  (default `~/.libscript/glassfish/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GLASSFISH_INSTALL_METHOD` (or global
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

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GLASSFISH_INSTALL_METHOD` | How to install glassfish. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GLASSFISH_VERSION`        | Specific version of glassfish to install.                                                                                                          | `latest`           | latest, lts      |
| `GLASSFISH_DOWNLOAD_URL`   | Override URL for downloading glassfish binary or archive artifacts.                                                                                | `none`             |                  |
| `GLASSFISH_RELEASES_URL`   | Override URL for querying glassfish available remote releases.                                                                                     | `none`             |                  |
| `GLASSFISH_LISTEN_PORT`    | TCP port on which the glassfish service listens.                                                                                                   | `8080`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
