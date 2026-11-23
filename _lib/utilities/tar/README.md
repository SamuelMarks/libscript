# GNU/BSD tar (`_lib/utilities/tar/`)

## Overview

Tape archive creation, inspection, and extraction utility supporting POSIX ustar and pax formats.

- **Tier**: `T1` (`_lib/utilities/tar/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `tar`, `archiver`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/tar/<version>)
./libscript.sh ls-remote tar
./libscript.sh install tar latest
./libscript.sh use tar latest
./libscript.sh which tar
./_lib/utilities/tar/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote tar
.\libscript.cmd install tar latest
.\libscript.cmd use tar latest
.\libscript.cmd which tar
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/tar/<version>`
  (default `~/.libscript/tar/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `TAR_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `TAR_INSTALL_METHOD` | How to install tar. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `TAR_VERSION`        | Specific version of tar to install.                                                                                                          | `latest` | latest, lts      |
| `TAR_DOWNLOAD_URL`   | Override URL for downloading tar binary or archive artifacts.                                                                                | `none`   |                  |
| `TAR_RELEASES_URL`   | Override URL for querying tar available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
