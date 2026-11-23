# rsync (`_lib/utilities/rsync/`)

## Overview

Fast incremental delta-transfer file synchronization and remote backup utility.

- **Tier**: `T1` (`_lib/utilities/rsync/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `rsync`, `file-sync`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/rsync/<version>)
./libscript.sh ls-remote rsync
./libscript.sh install rsync latest
./libscript.sh use rsync latest
./libscript.sh which rsync
./_lib/utilities/rsync/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote rsync
.\libscript.cmd install rsync latest
.\libscript.cmd use rsync latest
.\libscript.cmd which rsync
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/rsync/<version>`
  (default `~/.libscript/rsync/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `RSYNC_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `RSYNC_INSTALL_METHOD` | How to install rsync. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `RSYNC_VERSION`        | Specific version of rsync to install.                                                                                                          | `latest` | latest, lts      |
| `RSYNC_DOWNLOAD_URL`   | Override URL for downloading rsync binary or archive artifacts.                                                                                | `none`   |                  |
| `RSYNC_RELEASES_URL`   | Override URL for querying rsync available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
