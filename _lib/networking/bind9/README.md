# ISC BIND 9 DNS Server (`_lib/networking/bind9/`)

## Overview

ISC BIND 9 (named) authoritative, recursive, and DNSSEC-validating Domain Name System server and
utilities.

- **Tier**: `T1` (`_lib/networking/bind9/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `bind9`, `named`, `rndc`, `dig`

## Usage

```sh
# Install and manage the bind9 service daemon
./libscript.sh install bind9 latest
./libscript.sh start bind9
./libscript.sh status bind9
./libscript.sh logs bind9
./libscript.sh stop bind9
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install bind9 latest
.\libscript.cmd start bind9
.\libscript.cmd status bind9
.\libscript.cmd stop bind9
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/bind9/<version>`
  (default `~/.libscript/bind9/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `BIND9_INSTALL_METHOD` (or global
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

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BIND9_INSTALL_METHOD` | How to install bind9. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `BIND9_VERSION`        | Specific version of bind9 to install.                                                                                                          | `latest`           | latest, stable   |
| `BIND9_DOWNLOAD_URL`   | Override URL for downloading bind9 binary or archive artifacts.                                                                                | `none`             |                  |
| `BIND9_RELEASES_URL`   | Override URL for querying bind9 available remote releases.                                                                                     | `none`             |                  |
| `BIND9_LISTEN_PORT`    | TCP port on which the bind9 service listens.                                                                                                   | `53`               |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
