# Buck2 (`_lib/toolchains/buck2/`)

## Overview

Fast, hermetic, multi-language large-scale build system from Meta.

- **Tier**: `T1` (`_lib/toolchains/buck2/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `buck2`, `build-system`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/buck2/<version>)
./libscript.sh ls-remote buck2
./libscript.sh install buck2 latest
./libscript.sh use buck2 latest
./libscript.sh which buck2
./_lib/toolchains/buck2/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote buck2
.\libscript.cmd install buck2 latest
.\libscript.cmd use buck2 latest
.\libscript.cmd which buck2
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/buck2/<version>`
  (default `~/.libscript/buck2/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `BUCK2_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples   |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------ |
| `BUCK2_INSTALL_METHOD` | How to install buck2. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                    |
| `BUCK2_VERSION`        | Specific version of buck2 to install.                                                                                                          | `latest` | latest, 2024-12-01 |
| `BUCK2_DOWNLOAD_URL`   | Override URL for downloading buck2 binary or archive artifacts.                                                                                | `none`   |                    |
| `BUCK2_RELEASES_URL`   | Override URL for querying buck2 available remote releases.                                                                                     | `none`   |                    |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
