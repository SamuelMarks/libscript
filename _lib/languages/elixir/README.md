# Elixir Toolchain (`_lib/languages/elixir/`)

## Overview

A dynamic, functional language for building scalable and maintainable applications.

- **Tier**: `T1` (`_lib/languages/elixir/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `compiler`, `elixir`, `erlang`, `beam`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/elixir/<version>)
./libscript.sh ls-remote elixir
./libscript.sh install elixir latest
./libscript.sh use elixir latest
./libscript.sh which elixir
./_lib/languages/elixir/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote elixir
.\libscript.cmd install elixir latest
.\libscript.cmd use elixir latest
.\libscript.cmd which elixir
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/elixir/<version>`
  (default `~/.libscript/elixir/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `ELIXIR_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ELIXIR_VERSION`        | Specific version of elixir to install. Can be a numeric version or an alias.                                                                             | `latest`           | latest, stable   |
| `ELIXIR_INSTALL_METHOD` | Installation strategy for elixir: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `ELIXIR_DOWNLOAD_URL`   | Override URL for downloading elixir binary or archive artifacts.                                                                                         | `none`             |                  |
| `ELIXIR_RELEASES_URL`   | Override URL for querying elixir available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
