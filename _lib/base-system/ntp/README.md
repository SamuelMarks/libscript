# Network Time Protocol Daemon (ntpd) (`_lib/base-system/ntp/`)

## Overview

Reference Network Time Protocol (NTP) clock synchronization daemon (ntpd) and query tools.

- **Tier**: `T2` (`_lib/base-system/ntp/`)
- **Capabilities**: `sysroot-package`, `service-daemon`
- **Provides Virtual Capabilities**: `ntp`, `ntpd`, `ntpq`

## Usage

```sh
# Install and manage the ntp service daemon
./libscript.sh install ntp latest
./libscript.sh start ntp
./libscript.sh status ntp
./libscript.sh logs ntp
./libscript.sh stop ntp
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install ntp latest
.\libscript.cmd start ntp
.\libscript.cmd status ntp
.\libscript.cmd stop ntp
```

## Sysroot & Synthesis Integration

- **`T3` Sysroot Staging**: Respects `LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
  `LIBSCRIPT_TARGET_TRIPLET`, and `LIBSCRIPT_OFFLINE=1` when compiled into OS images or unikernels
  by `synthesis/` and `engine/solver/execute_plan.*`.
- **Override Strategy**: Control build/acquisition mode via `NTP_INSTALL_METHOD` or global
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

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NTP_INSTALL_METHOD` | How to install ntp. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `NTP_VERSION`        | Specific version of ntp to install.                                                                                                          | `latest`           | latest, stable   |
| `NTP_DOWNLOAD_URL`   | Override URL for downloading ntp binary or archive artifacts.                                                                                | `none`             |                  |
| `NTP_RELEASES_URL`   | Override URL for querying ntp available remote releases.                                                                                     | `none`             |                  |
| `NTP_LISTEN_PORT`    | TCP port on which the ntp service listens.                                                                                                   | `123`              |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
