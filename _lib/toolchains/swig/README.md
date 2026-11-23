# SWIG (`_lib/toolchains/swig/`)

## Overview

Simplified Wrapper and Interface Generator connecting C/C++ with high-level languages.

- **Tier**: `T1` (`_lib/toolchains/swig/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/swig/<version>)
./libscript.sh ls-remote swig
./libscript.sh install swig latest
./libscript.sh use swig latest
./libscript.sh which swig
./_lib/toolchains/swig/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote swig
.\libscript.cmd install swig latest
.\libscript.cmd use swig latest
.\libscript.cmd which swig
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/swig/<version>`
  (default `~/.libscript/swig/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `SWIG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `SWIG_INSTALL_METHOD` | How to install swig. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `SWIG_VERSION`        | Specific version of swig to install.                                                                                                          | `latest` | latest, 4.3.0    |
| `SWIG_DOWNLOAD_URL`   | Override URL for downloading swig binary or archive artifacts.                                                                                | `none`   |                  |
| `SWIG_RELEASES_URL`   | Override URL for querying swig available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
