# cdd-c C89 CST Transformer (`_lib/toolchains/cdd-c/`)

## Overview

Lossless C89 Concrete Syntax Tree (CST) parser and 4-pass lowering transformer (cdd-c-transform).

- **Tier**: `T1` (`_lib/toolchains/cdd-c/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `cdd-c`, `cdd-c-transform`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/cdd-c/<version>)
./libscript.sh ls-remote cdd-c
./libscript.sh install cdd-c latest
./libscript.sh use cdd-c latest
./libscript.sh which cdd-c
./_lib/toolchains/cdd-c/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote cdd-c
.\libscript.cmd install cdd-c latest
.\libscript.cmd use cdd-c latest
.\libscript.cmd which cdd-c
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/cdd-c/<version>`
  (default `~/.libscript/cdd-c/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CDD_C_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default       | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `CDD_C_INSTALL_METHOD` | How to install cdd-c. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `CDD_C_VERSION`        | Specific version of cdd-c to install.                                                                                                          | `latest`      | latest, lts      |
| `CDD_C_DOWNLOAD_URL`   | Override URL for downloading cdd-c binary or archive artifacts.                                                                                | `none`        |                  |
| `CDD_C_RELEASES_URL`   | Override URL for querying cdd-c available remote releases.                                                                                     | `none`        |                  |
| `CDD_C_REPO_DIR`       | Optional local checkout path for cdd-c when building standalone cdd-c-transform.                                                               | ``            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
