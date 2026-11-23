# vcpkg-tool (`_lib/toolchains/vcpkg-tool/`)

## Overview

Native C++ command-line binary frontend for the vcpkg package manager.

- **Tier**: `T1` (`_lib/toolchains/vcpkg-tool/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `vcpkg-tool`, `vcpkg-cli`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/vcpkg-tool/<version>)
./libscript.sh ls-remote vcpkg-tool
./libscript.sh install vcpkg-tool latest
./libscript.sh use vcpkg-tool latest
./libscript.sh which vcpkg-tool
./_lib/toolchains/vcpkg-tool/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote vcpkg-tool
.\libscript.cmd install vcpkg-tool latest
.\libscript.cmd use vcpkg-tool latest
.\libscript.cmd which vcpkg-tool
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/vcpkg-tool/<version>`
  (default `~/.libscript/vcpkg-tool/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `VCPKG_TOOL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                         | Default            | Aliases/Examples   |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------ |
| `VCPKG_TOOL_INSTALL_METHOD` | How to install vcpkg-tool. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                    |
| `VCPKG_TOOL_VERSION`        | Specific version of vcpkg-tool to install.                                                                                                          | `latest`           | latest, 2024-12-09 |
| `VCPKG_TOOL_DOWNLOAD_URL`   | Override URL for downloading vcpkg-tool binary or archive artifacts.                                                                                | `none`             |                    |
| `VCPKG_TOOL_RELEASES_URL`   | Override URL for querying vcpkg-tool available remote releases.                                                                                     | `none`             |                    |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
