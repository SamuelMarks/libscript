# ccache (`_lib/toolchains/ccache/`)

## Overview

A fast C and C++ compiler cache.

- **Tier**: `T1` (`_lib/toolchains/ccache/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `ccache`, `compiler-cache`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ccache/<version>)
./libscript.sh ls-remote ccache
./libscript.sh install ccache latest
./libscript.sh use ccache latest
./libscript.sh which ccache
./_lib/toolchains/ccache/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ccache
.\libscript.cmd install ccache latest
.\libscript.cmd use ccache latest
.\libscript.cmd which ccache
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ccache/<version>`
  (default `~/.libscript/ccache/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CCACHE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default            | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CCACHE_INSTALL_METHOD` | How to install ccache. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `CCACHE_VERSION`        | Specific version of ccache to install.                                                                                                          | `latest`           | latest, 4.10.2   |
| `CCACHE_DOWNLOAD_URL`   | Override URL for downloading ccache binary or archive artifacts.                                                                                | `none`             |                  |
| `CCACHE_RELEASES_URL`   | Override URL for querying ccache available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
