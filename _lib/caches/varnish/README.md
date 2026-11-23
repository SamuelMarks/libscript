# Varnish Cache (`_lib/caches/varnish/`)

## Overview

High-performance caching HTTP reverse proxy accelerator with flexible VCL policy configuration.

- **Tier**: `T1` (`_lib/caches/varnish/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `varnish`, `http-cache`, `cache`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the varnish service daemon
./libscript.sh install varnish latest
./libscript.sh start varnish
./libscript.sh status varnish
./libscript.sh logs varnish
./libscript.sh stop varnish
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install varnish latest
.\libscript.cmd start varnish
.\libscript.cmd status varnish
.\libscript.cmd stop varnish
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/varnish/<version>`
  (default `~/.libscript/varnish/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `VARNISH_INSTALL_METHOD` (or global
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

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `VARNISH_INSTALL_METHOD` | How to install varnish. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `VARNISH_VERSION`        | Specific version of varnish to install.                                                                                                          | `latest` | latest, lts      |
| `VARNISH_DOWNLOAD_URL`   | Override URL for downloading varnish binary or archive artifacts.                                                                                | `none`   |                  |
| `VARNISH_RELEASES_URL`   | Override URL for querying varnish available remote releases.                                                                                     | `none`   |                  |
| `VARNISH_LISTEN_PORT`    | TCP port on which the varnish service listens.                                                                                                   | `6081`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
