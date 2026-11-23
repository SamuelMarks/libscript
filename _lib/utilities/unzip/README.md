# Info-ZIP UnZip (`_lib/utilities/unzip/`)

## Overview

Portable Info-ZIP extraction and integrity testing utility for PKZIP (.zip) archives.

- **Tier**: `T1` (`_lib/utilities/unzip/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `unzip`, `zip-extractor`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/unzip/<version>)
./libscript.sh ls-remote unzip
./libscript.sh install unzip latest
./libscript.sh use unzip latest
./libscript.sh which unzip
./_lib/utilities/unzip/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote unzip
.\libscript.cmd install unzip latest
.\libscript.cmd use unzip latest
.\libscript.cmd which unzip
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/unzip/<version>`
  (default `~/.libscript/unzip/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `UNZIP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `UNZIP_INSTALL_METHOD` | How to install unzip. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `UNZIP_VERSION`        | Specific version of unzip to install.                                                                                                          | `latest` | latest, lts      |
| `UNZIP_DOWNLOAD_URL`   | Override URL for downloading unzip binary or archive artifacts.                                                                                | `none`   |                  |
| `UNZIP_RELEASES_URL`   | Override URL for querying unzip available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
