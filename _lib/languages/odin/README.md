# Odin (`_lib/languages/odin/`)

## Overview

Data-oriented systems programming language built for high performance, simplicity, and modern
software development.

- **Tier**: `T1` (`_lib/languages/odin/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/odin/<version>)
./libscript.sh ls-remote odin
./libscript.sh install odin latest
./libscript.sh use odin latest
./libscript.sh which odin
./_lib/languages/odin/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote odin
.\libscript.cmd install odin latest
.\libscript.cmd use odin latest
.\libscript.cmd which odin
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/odin/<version>`
  (default `~/.libscript/odin/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ODIN_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ODIN_INSTALL_METHOD` | How to install odin. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `ODIN_VERSION`        | Specific version of odin to install.                                                                                                          | `latest`           | latest, lts      |
| `ODIN_DOWNLOAD_URL`   | Override URL for downloading odin binary or archive artifacts.                                                                                | `none`             |                  |
| `ODIN_RELEASES_URL`   | Override URL for querying odin available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
