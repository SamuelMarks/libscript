# Rustup

Bootstrap module for `rustup` (Rust toolchain installer).

## Usage

Ensures the `rustup` executable is available for managing Rust toolchains and supplementary cargo
components.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RUSTUP_INSTALL_METHOD` | How to install RUSTUP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `RUSTUP_VERSION`        | Specific version of rustup to install.                                                                                                                                 | `latest`           |                  |
| `RUSTUP_DOWNLOAD_URL`   | Override URL for downloading rustup binary or archive artifacts.                                                                                                       | `none`             |                  |
| `RUSTUP_RELEASES_URL`   | Override URL for querying rustup available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
