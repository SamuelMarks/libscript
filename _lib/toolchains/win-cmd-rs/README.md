# win-cmd-rs Batch Interpreter & Linter (`_lib/toolchains/win-cmd-rs/`)

## Overview

Safe Rust Windows cmd.exe interpreter (wincmd) and linear Packrat 50-rule linter / 4-pass CST
rewriter (wincheck).

- **Tier**: `T1` (`_lib/toolchains/win-cmd-rs/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `win-cmd-rs`, `wincmd`, `wincheck`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/win-cmd-rs/<version>)
./libscript.sh ls-remote win-cmd-rs
./libscript.sh install win-cmd-rs latest
./libscript.sh use win-cmd-rs latest
./libscript.sh which win-cmd-rs
./_lib/toolchains/win-cmd-rs/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote win-cmd-rs
.\libscript.cmd install win-cmd-rs latest
.\libscript.cmd use win-cmd-rs latest
.\libscript.cmd which win-cmd-rs
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/win-cmd-rs/<version>`
  (default `~/.libscript/win-cmd-rs/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `WIN_CMD_RS_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                                                                              | Default                                                               | Aliases/Examples           |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | -------------------------- |
| `WIN_CMD_RS_INSTALL_METHOD` | How to install win-cmd-rs. 'libscript_native' downloads prebuilt GitHub Release binaries into isolated version directories, 'system' uses the OS package manager, and 'from-source' compiles with Cargo. | `libscript_native`                                                    |                            |
| `WIN_CMD_RS_VERSION`        | Specific version or alias of win-cmd-rs to install.                                                                                                                                                      | `latest`                                                              | latest, stable, lts, 0.0.1 |
| `WIN_CMD_RS_DOWNLOAD_URL`   | Override URL or template ({VERSION}, {RUST_TARGET}, {EXT}) for downloading win-cmd-rs release archives.                                                                                                  | `none`                                                                |                            |
| `WIN_CMD_RS_RELEASES_URL`   | Override URL for querying available remote win-cmd-rs GitHub releases.                                                                                                                                   | `https://api.github.com/repos/SamuelMarks/win-cmd-rs/releases/latest` |                            |
| `WIN_CMD_RS_CHECKSUM`       | Optional explicit SHA-256 digest override for verifying custom win-cmd-rs release archives.                                                                                                              | `none`                                                                |                            |
| `WIN_CMD_RS_REPO_DIR`       | Optional local checkout path for compiling win-cmd-rs offline when using the from-source method.                                                                                                         | ``                                                                    |                            |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
