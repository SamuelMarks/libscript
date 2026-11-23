# PHP-FPM (`_lib/app-servers/php-fpm/`)

## Overview

PHP FastCGI Process Manager daemon with adaptive process spawning for high-traffic PHP sites.

- **Tier**: `T1` (`_lib/app-servers/php-fpm/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `php-fpm`, `fastcgi`, `app-server`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the php-fpm service daemon
./libscript.sh install php-fpm latest
./libscript.sh start php-fpm
./libscript.sh status php-fpm
./libscript.sh logs php-fpm
./libscript.sh stop php-fpm
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install php-fpm latest
.\libscript.cmd start php-fpm
.\libscript.cmd status php-fpm
.\libscript.cmd stop php-fpm
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/php-fpm/<version>`
  (default `~/.libscript/php-fpm/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `PHP_FPM_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `PHP_FPM_INSTALL_METHOD` | How to install php-fpm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PHP_FPM_VERSION`        | Specific version of php-fpm to install.                                                                                                          | `latest` | latest, lts      |
| `PHP_FPM_DOWNLOAD_URL`   | Override URL for downloading php-fpm binary or archive artifacts.                                                                                | `none`   |                  |
| `PHP_FPM_RELEASES_URL`   | Override URL for querying php-fpm available remote releases.                                                                                     | `none`   |                  |
| `PHP_FPM_LISTEN_PORT`    | TCP port on which the php-fpm service listens.                                                                                                   | `9000`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
