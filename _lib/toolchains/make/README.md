# GNU Make (`_lib/toolchains/make/`)

## Overview

Standard build automation tool generating executables and targets from Makefiles.

- **Tier**: `T1` (`_lib/toolchains/make/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `make`, `gmake`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/make/<version>)
./libscript.sh ls-remote make
./libscript.sh install make latest
./libscript.sh use make latest
./libscript.sh which make
./_lib/toolchains/make/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote make
.\libscript.cmd install make latest
.\libscript.cmd use make latest
.\libscript.cmd which make
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/make/<version>`
  (default `~/.libscript/make/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `MAKE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `MAKE_INSTALL_METHOD` | How to install make. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `MAKE_VERSION`        | Specific version of make to install.                                                                                                          | `latest` | latest, 4.4.1    |
| `MAKE_DOWNLOAD_URL`   | Override URL for downloading make binary or archive artifacts.                                                                                | `none`   |                  |
| `MAKE_RELEASES_URL`   | Override URL for querying make available remote releases.                                                                                     | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
