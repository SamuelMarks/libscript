# PHP Runtime (`_lib/languages/php/`)

## Overview

A popular general-purpose scripting language that is especially suited to web development.

- **Tier**: `T1` (`_lib/languages/php/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `runtime`, `php`
- **Target OS Exclusions (`manifest.json`)**: `sunos`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/php/<version>)
./libscript.sh ls-remote php
./libscript.sh install php latest
./libscript.sh use php latest
./libscript.sh which php
./_lib/languages/php/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote php
.\libscript.cmd install php latest
.\libscript.cmd use php latest
.\libscript.cmd which php
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/php/<version>`
  (default `~/.libscript/php/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `PHP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PHP_INSTALL_METHOD` | Installation strategy for php: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PHP_VERSION`        | Version of PHP Runtime to install                                                                                                                     | `latest`           |                  |
| `PHP_DOWNLOAD_URL`   | Override URL for downloading php binary or archive artifacts.                                                                                         | `none`             |                  |
| `PHP_RELEASES_URL`   | Override URL for querying php available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
