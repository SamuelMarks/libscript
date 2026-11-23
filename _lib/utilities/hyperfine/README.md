# hyperfine CLI Benchmarker (`_lib/utilities/hyperfine/`)

## Overview

Command-line statistical benchmarking tool supporting warmup runs, prepare hooks, and JSON sample
export.

- **Tier**: `T1` (`_lib/utilities/hyperfine/`)
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/hyperfine/<version>)
./libscript.sh ls-remote hyperfine
./libscript.sh install hyperfine latest
./libscript.sh use hyperfine latest
./libscript.sh which hyperfine
./_lib/utilities/hyperfine/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote hyperfine
.\libscript.cmd install hyperfine latest
.\libscript.cmd use hyperfine latest
.\libscript.cmd which hyperfine
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/hyperfine/<version>`
  (default `~/.libscript/hyperfine/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `HYPERFINE_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HYPERFINE_INSTALL_METHOD` | How to install hyperfine. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `HYPERFINE_VERSION`        | Specific version of hyperfine to install.                                                                                                          | `1.19.0`           | latest, lts      |
| `HYPERFINE_DOWNLOAD_URL`   | Override URL for downloading hyperfine binary or archive artifacts.                                                                                | `none`             |                  |
| `HYPERFINE_RELEASES_URL`   | Override URL for querying hyperfine available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
