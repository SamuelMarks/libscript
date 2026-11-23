# GNU Automake (`_lib/toolchains/automake/`)

## Overview

Tool for automatically generating GNU Standards-compliant Makefile.in files.

- **Tier**: `T1` (`_lib/toolchains/automake/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/automake/<version>)
./libscript.sh ls-remote automake
./libscript.sh install automake latest
./libscript.sh use automake latest
./libscript.sh which automake
./_lib/toolchains/automake/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote automake
.\libscript.cmd install automake latest
.\libscript.cmd use automake latest
.\libscript.cmd which automake
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/automake/<version>`
  (default `~/.libscript/automake/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `AUTOMAKE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                       | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `AUTOMAKE_INSTALL_METHOD` | How to install automake. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `AUTOMAKE_VERSION`        | Specific version of automake to install.                                                                                                          | `latest` | latest, 1.17     |
| `AUTOMAKE_DOWNLOAD_URL`   | Override URL for downloading automake binary or archive artifacts.                                                                                | `none`   |                  |
| `AUTOMAKE_RELEASES_URL`   | Override URL for querying automake available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
