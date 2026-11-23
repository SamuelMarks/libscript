# Upstream GCC C Torture Execute Conformance Suite (`_lib/toolchains/gcc-torture/`)

## Overview

Standalone version manager for the upstream GCC gcc.c-torture/execute C execution test corpus with
DejaGnu .x and nested-function filter manifests.

- **Tier**: `T1` (`_lib/toolchains/gcc-torture/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/gcc-torture/<version>)
./libscript.sh ls-remote gcc-torture
./libscript.sh install gcc-torture latest
./libscript.sh use gcc-torture latest
./libscript.sh which gcc-torture
./_lib/toolchains/gcc-torture/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote gcc-torture
.\libscript.cmd install gcc-torture latest
.\libscript.cmd use gcc-torture latest
.\libscript.cmd which gcc-torture
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/gcc-torture/<version>` (default `~/.libscript/gcc-torture/<version>`) and
  synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `GCC_TORTURE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                            | Description                                                                                                                                          | Default            | Aliases/Examples |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GCC_TORTURE_INSTALL_METHOD`        | How to install gcc-torture. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GCC_TORTURE_VERSION`               | Specific version of gcc-torture to install.                                                                                                          | `14.2.0`           | latest, lts      |
| `GCC_TORTURE_DOWNLOAD_URL`          | Override URL for downloading gcc-torture binary or archive artifacts.                                                                                | `none`             |                  |
| `GCC_TORTURE_RELEASES_URL`          | Override URL for querying gcc-torture available remote releases.                                                                                     | `none`             |                  |
| `GCC_TORTURE_DIR`                   | Filesystem directory containing extracted gcc.c-torture/execute/*.c test cases.                                                                      | `none`             |                  |
| `GCC_TORTURE_SKIP_NESTED_FUNCTIONS` | Whether tests relying on non-standard GNU nested functions or DejaGnu target-skip .x directives are filtered out.                                    | `true`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
