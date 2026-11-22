# Mas

Bootstrap module for the `mas` package manager (Mac App Store command line interface).

## Usage

Ensures the `mas` executable is available for automating Mac App Store installs.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                                         | Default            | Aliases/Examples |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MAS_INSTALL_METHOD` | How to install MAS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `MAS_VERSION`        | Specific version of mas to install.                                                                                                                                 | `latest`           |                  |
| `MAS_DOWNLOAD_URL`   | Override URL for downloading mas binary or archive artifacts.                                                                                                       | `none`             |                  |
| `MAS_RELEASES_URL`   | Override URL for querying mas available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
