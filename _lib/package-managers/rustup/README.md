# Rustup

**Tier**: `T1` (`_lib/package-managers/rustup/`) | **Capabilities**: `userland-package`

Bootstrap module for `rustup` (Rust toolchain installer).

## Usage

Ensures the `rustup` executable is available for managing Rust toolchains and supplementary cargo
components.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RUSTUP_INSTALL_METHOD` | Installation strategy for rustup: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `RUSTUP_VERSION`        | Specific version of rustup to install.                                                                                                                   | `latest`           |                  |
| `RUSTUP_DOWNLOAD_URL`   | Override URL for downloading rustup binary or archive artifacts.                                                                                         | `none`             |                  |
| `RUSTUP_RELEASES_URL`   | Override URL for querying rustup available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
