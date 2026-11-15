# Cargo

Bootstrap module for the `cargo` package manager.

## Usage

Ensures the `cargo` executable is available. This relies on the core language toolchain (e.g.,
Rust).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CARGO_INSTALL_METHOD` | How to install CARGO. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `CARGO_VERSION`        | Specific version of cargo to install.                                                                                                                                 | `latest`           |                  |
| `CARGO_DOWNLOAD_URL`   | Override URL for downloading cargo binary or archive artifacts.                                                                                                       | `none`             |                  |
| `CARGO_RELEASES_URL`   | Override URL for querying cargo available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
