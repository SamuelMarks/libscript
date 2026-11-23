# cgit (`_lib/git-servers/cgit/`)

## Overview

Hyperfast C CGI web frontend for Git repositories with built-in caching.

- **Tier**: `T1` (`_lib/git-servers/cgit/`)
- **Capabilities**: `userland-package`, `service-daemon`
- **Provides Virtual Capabilities**: `cgit`, `git-web`
- **Target OS Exclusions (`manifest.json`)**: `windows`

## Usage

```sh
# Install and manage the cgit service daemon
./libscript.sh install cgit latest
./libscript.sh start cgit
./libscript.sh status cgit
./libscript.sh logs cgit
./libscript.sh stop cgit
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd install cgit latest
.\libscript.cmd start cgit
.\libscript.cmd status cgit
.\libscript.cmd stop cgit
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/cgit/<version>`
  (default `~/.libscript/cgit/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CGIT_INSTALL_METHOD` (or global
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

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CGIT_INSTALL_METHOD` | How to install cgit. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `CGIT_VERSION`        | Specific version of cgit to install.                                                                                                          | `latest` | latest, lts      |
| `CGIT_DOWNLOAD_URL`   | Override URL for downloading cgit binary or archive artifacts.                                                                                | `none`   |                  |
| `CGIT_RELEASES_URL`   | Override URL for querying cgit available remote releases.                                                                                     | `none`   |                  |
| `CGIT_LISTEN_PORT`    | TCP port on which the cgit service listens.                                                                                                   | `80`     |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
