# Bundler

Bootstrap module for the `bundler` package manager.

## Usage

Ensures the `bundler` executable is available. This relies on the core language toolchain
appropriate for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                                             | Default            | Aliases/Examples |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `BUNDLER_INSTALL_METHOD` | How to install BUNDLER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `BUNDLER_VERSION`        | Specific version of bundler to install.                                                                                                                                 | `latest`           |                  |
| `BUNDLER_DOWNLOAD_URL`   | Override URL for downloading bundler binary or archive artifacts.                                                                                                       | `none`             |                  |
| `BUNDLER_RELEASES_URL`   | Override URL for querying bundler available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
