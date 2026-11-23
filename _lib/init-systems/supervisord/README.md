# Supervisor Process Control System (`_lib/init-systems/supervisord/`)

## Overview

Supervisor client/server process control daemon (supervisord and supervisorctl) for UNIX-like
operating systems.

- **Tier**: `T2` (`_lib/init-systems/supervisord/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `supervisord`, `supervisor`, `supervisorctl`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `macos`, `freebsd`, `openbsd`, `netbsd`,
  `sunos`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the supervisord service daemon
./libscript.sh install supervisord latest
./libscript.sh start supervisord
./libscript.sh status supervisord
./libscript.sh logs supervisord
./libscript.sh stop supervisord
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install supervisord latest
.\libscript.cmd start supervisord
.\libscript.cmd status supervisord
.\libscript.cmd stop supervisord
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `SUPERVISORD_INSTALL_METHOD` or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD` (`libscript_native`, `from-source`, or `system`).

## Lifecycle Hooks (`hooks/`)

Provides dual-layer lifecycle hooks invoked by `T0` `engine/common/hooks.{sh,cmd}` and `Plane A`
traits (`traits/`): `announce.{sh,cmd}`, `backup.{sh,cmd}`, `configure.{sh,cmd}`,
`log_stream.{sh,cmd}`, `maintenance.{sh,cmd}`, `metrics.{sh,cmd}`, `probe.{sh,cmd}`,
`restore.{sh,cmd}`, `rollback.{sh,cmd}`, `upgrade.{sh,cmd}`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                     | Description                                                                                                                                          | Default            | Aliases/Examples |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SUPERVISORD_INSTALL_METHOD` | How to install supervisord. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `SUPERVISORD_VERSION`        | Specific version of supervisord to install.                                                                                                          | `latest`           | latest, stable   |
| `SUPERVISORD_DOWNLOAD_URL`   | Override URL for downloading supervisord binary or archive artifacts.                                                                                | `none`             |                  |
| `SUPERVISORD_RELEASES_URL`   | Override URL for querying supervisord available remote releases.                                                                                     | `none`             |                  |
| `SUPERVISORD_LISTEN_PORT`    | TCP port on which the supervisord service listens.                                                                                                   | `9001`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
