# MSBuild (`_lib/toolchains/msbuild/`)

## Overview

Microsoft Build Engine for .NET and Visual C++ project files.

- **Tier**: `T1` (`_lib/toolchains/msbuild/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/msbuild/<version>)
./libscript.sh ls-remote msbuild
./libscript.sh install msbuild latest
./libscript.sh use msbuild latest
./libscript.sh which msbuild
./_lib/toolchains/msbuild/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote msbuild
.\libscript.cmd install msbuild latest
.\libscript.cmd use msbuild latest
.\libscript.cmd which msbuild
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/msbuild/<version>`
  (default `~/.libscript/msbuild/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `MSBUILD_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `MSBUILD_INSTALL_METHOD` | How to install msbuild. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `MSBUILD_VERSION`        | Specific version of msbuild to install.                                                                                                          | `latest` | latest, 17.12.6  |
| `MSBUILD_DOWNLOAD_URL`   | Override URL for downloading msbuild binary or archive artifacts.                                                                                | `none`   |                  |
| `MSBUILD_RELEASES_URL`   | Override URL for querying msbuild available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
