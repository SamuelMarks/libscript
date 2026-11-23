# Ninja (`_lib/toolchains/ninja/`)

## Overview

A small build system with a focus on speed.

- **Tier**: `T1` (`_lib/toolchains/ninja/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `ninja`, `build-system`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ninja/<version>)
./libscript.sh ls-remote ninja
./libscript.sh install ninja latest
./libscript.sh use ninja latest
./libscript.sh which ninja
./_lib/toolchains/ninja/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ninja
.\libscript.cmd install ninja latest
.\libscript.cmd use ninja latest
.\libscript.cmd which ninja
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ninja/<version>`
  (default `~/.libscript/ninja/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `NINJA_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples       |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------------- |
| `NINJA_INSTALL_METHOD` | How to install ninja. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                        |
| `NINJA_VERSION`        | Specific version of ninja to install.                                                                                                          | `latest`           | latest, 1.12.1, 1.11.1 |
| `NINJA_DOWNLOAD_URL`   | Override URL for downloading ninja binary or archive artifacts.                                                                                | `none`             |                        |
| `NINJA_RELEASES_URL`   | Override URL for querying ninja available remote releases.                                                                                     | `none`             |                        |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
