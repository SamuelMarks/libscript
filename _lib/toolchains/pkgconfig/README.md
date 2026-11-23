# pkg-config / pkgconf (`_lib/toolchains/pkgconfig/`)

## Overview

Compiler and linker metadata query tool for installed libraries.

- **Tier**: `T1` (`_lib/toolchains/pkgconfig/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `pkgconfig`, `pkg-config`, `pkgconf`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/pkgconfig/<version>)
./libscript.sh ls-remote pkgconfig
./libscript.sh install pkgconfig latest
./libscript.sh use pkgconfig latest
./libscript.sh which pkgconfig
./_lib/toolchains/pkgconfig/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote pkgconfig
.\libscript.cmd install pkgconfig latest
.\libscript.cmd use pkgconfig latest
.\libscript.cmd which pkgconfig
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/pkgconfig/<version>`
  (default `~/.libscript/pkgconfig/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `PKGCONFIG_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default  | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PKGCONFIG_INSTALL_METHOD` | How to install pkgconfig. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PKGCONFIG_VERSION`        | Specific version of pkgconfig to install.                                                                                                          | `latest` | latest, 2.3.0    |
| `PKGCONFIG_DOWNLOAD_URL`   | Override URL for downloading pkgconfig binary or archive artifacts.                                                                                | `none`   |                  |
| `PKGCONFIG_RELEASES_URL`   | Override URL for querying pkgconfig available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
