# Nuget

Bootstrap module for the `nuget` package manager.

## Usage

Ensures the `nuget` executable is available. Uses libscript_native package manager mapping (e.g.,
`nuget` package on Debian).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NUGET_INSTALL_METHOD` | How to install NUGET. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `NUGET_VERSION`        | Specific version of nuget to install.                                                                                                                                 | `latest`           |                  |
| `NUGET_DOWNLOAD_URL`   | Override URL for downloading nuget binary or archive artifacts.                                                                                                       | `none`             |                  |
| `NUGET_RELEASES_URL`   | Override URL for querying nuget available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
