# Doxygen Documentation Generator (`_lib/toolchains/doxygen/`)

## Overview

Doxygen documentation analyzer and XML symbol extractor for auditing C89 docstring coverage.

- **Tier**: `T1` (`_lib/toolchains/doxygen/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/doxygen/<version>)
./libscript.sh ls-remote doxygen
./libscript.sh install doxygen latest
./libscript.sh use doxygen latest
./libscript.sh which doxygen
./_lib/toolchains/doxygen/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote doxygen
.\libscript.cmd install doxygen latest
.\libscript.cmd use doxygen latest
.\libscript.cmd which doxygen
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/doxygen/<version>`
  (default `~/.libscript/doxygen/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `DOXYGEN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `DOXYGEN_INSTALL_METHOD` | How to install doxygen. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `DOXYGEN_VERSION`        | Specific version of doxygen to install.                                                                                                          | `1.12.0` | latest, lts      |
| `DOXYGEN_DOWNLOAD_URL`   | Override URL for downloading doxygen binary or archive artifacts.                                                                                | `none`   |                  |
| `DOXYGEN_RELEASES_URL`   | Override URL for querying doxygen available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
