# GNU Awk (gawk) (`_lib/utilities/gawk/`)

## Overview

Standalone GNU Awk 5.4+ pattern scanning and processing language with native Windows (MSVC) and
MS-DOS (dos32) builds via SamuelMarks/gawk-windows.

- **Tier**: `T1` (`_lib/utilities/gawk/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `gawk`, `gawk-windows`, `awk`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/gawk/<version>)
./libscript.sh ls-remote gawk
./libscript.sh install gawk latest
./libscript.sh use gawk latest
./libscript.sh which gawk
./_lib/utilities/gawk/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote gawk
.\libscript.cmd install gawk latest
.\libscript.cmd use gawk latest
.\libscript.cmd which gawk
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/gawk/<version>`
  (default `~/.libscript/gawk/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `GAWK_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                                    | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `GAWK_INSTALL_METHOD` | How to install gawk. 'libscript_native' uses isolated version dirs (dos32 on MS-DOS, PE on Windows), 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GAWK_VERSION`        | Specific version of gawk to install (e.g., 5.4.60 on Windows/MS-DOS, 5.3.1 on POSIX, or latest).                                                                               | `latest`           | latest, lts      |
| `GAWK_DOWNLOAD_URL`   | Override URL for downloading gawk binary or archive artifacts.                                                                                                                 | `none`             |                  |
| `GAWK_RELEASES_URL`   | Override URL for querying gawk available remote releases.                                                                                                                      | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
