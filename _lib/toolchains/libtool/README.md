# GNU Libtool (`_lib/toolchains/libtool/`)

## Overview

Generic shared library support script abstracting platform library conventions.

- **Tier**: `T1` (`_lib/toolchains/libtool/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/libtool/<version>)
./libscript.sh ls-remote libtool
./libscript.sh install libtool latest
./libscript.sh use libtool latest
./libscript.sh which libtool
./_lib/toolchains/libtool/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote libtool
.\libscript.cmd install libtool latest
.\libscript.cmd use libtool latest
.\libscript.cmd which libtool
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/libtool/<version>`
  (default `~/.libscript/libtool/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `LIBTOOL_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `LIBTOOL_INSTALL_METHOD` | How to install libtool. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `LIBTOOL_VERSION`        | Specific version of libtool to install.                                                                                                          | `latest` | latest, 2.5.4    |
| `LIBTOOL_DOWNLOAD_URL`   | Override URL for downloading libtool binary or archive artifacts.                                                                                | `none`   |                  |
| `LIBTOOL_RELEASES_URL`   | Override URL for querying libtool available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
