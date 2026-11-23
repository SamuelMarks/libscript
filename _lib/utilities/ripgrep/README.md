# ripgrep (`_lib/utilities/ripgrep/`)

## Overview

Line-oriented recursive regex search tool (rg) written in Rust respecting gitignore rules.

- **Tier**: `T1` (`_lib/utilities/ripgrep/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `ripgrep`, `rg`, `code-search`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/ripgrep/<version>)
./libscript.sh ls-remote ripgrep
./libscript.sh install ripgrep latest
./libscript.sh use ripgrep latest
./libscript.sh which ripgrep
./_lib/utilities/ripgrep/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote ripgrep
.\libscript.cmd install ripgrep latest
.\libscript.cmd use ripgrep latest
.\libscript.cmd which ripgrep
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/ripgrep/<version>`
  (default `~/.libscript/ripgrep/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `RIPGREP_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `RIPGREP_INSTALL_METHOD` | How to install ripgrep. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `RIPGREP_VERSION`        | Specific version of ripgrep to install.                                                                                                          | `latest`           | latest, lts      |
| `RIPGREP_DOWNLOAD_URL`   | Override URL for downloading ripgrep binary or archive artifacts.                                                                                | `none`             |                  |
| `RIPGREP_RELEASES_URL`   | Override URL for querying ripgrep available remote releases.                                                                                     | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
