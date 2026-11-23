# Cargo Binstall

**Tier**: `T1` (`_lib/package-managers/cargo-binstall/`) | **Capabilities**: `userland-package`

Bootstrap module for the `cargo-binstall` package manager.

## Usage

Ensures the `cargo-binstall` executable is available. This relies on the core language toolchain
appropriate for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `CARGO_BINSTALL_INSTALL_METHOD` | Installation strategy for cargo-binstall: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `CARGO_BINSTALL_VERSION`        | Specific version of cargo-binstall to install.                                                                                                                   | `latest`           |                  |
| `CARGO_BINSTALL_DOWNLOAD_URL`   | Override URL for downloading cargo-binstall binary or archive artifacts.                                                                                         | `none`             |                  |
| `CARGO_BINSTALL_RELEASES_URL`   | Override URL for querying cargo-binstall available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
