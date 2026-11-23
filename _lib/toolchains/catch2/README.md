# Catch2 v3 C++17 Unit Testing Framework (`_lib/toolchains/catch2/`)

## Overview

Standalone version manager and CMake multi-TU source builder for Catch2 (pinned default 3.7.1) with
upstream CTest verification.

- **Tier**: `T1` (`_lib/toolchains/catch2/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/catch2/<version>)
./libscript.sh ls-remote catch2
./libscript.sh install catch2 latest
./libscript.sh use catch2 latest
./libscript.sh which catch2
./_lib/toolchains/catch2/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote catch2
.\libscript.cmd install catch2 latest
.\libscript.cmd use catch2 latest
.\libscript.cmd which catch2
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/catch2/<version>`
  (default `~/.libscript/catch2/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `CATCH2_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default       | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `CATCH2_INSTALL_METHOD` | How to install catch2. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `CATCH2_VERSION`        | Specific version of catch2 to install.                                                                                                          | `3.7.1`       | latest, lts      |
| `CATCH2_DOWNLOAD_URL`   | Override URL for downloading catch2 binary or archive artifacts.                                                                                | `none`        |                  |
| `CATCH2_RELEASES_URL`   | Override URL for querying catch2 available remote releases.                                                                                     | `none`        |                  |
| `CATCH2_RUN_TESTS`      | Whether to build and execute Catch2's SelfTest CTest suite during source compilation.                                                           | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
