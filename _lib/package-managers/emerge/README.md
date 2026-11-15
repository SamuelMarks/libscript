# Emerge

Bootstrap module for the Gentoo `emerge` package manager.

## Usage

Ensures the `emerge` executable is available (usually built-in on Gentoo).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `EMERGE_INSTALL_METHOD` | How to install EMERGE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `EMERGE_VERSION`        | Specific version of emerge to install.                                                                                                                                 | `latest`           |                  |
| `EMERGE_DOWNLOAD_URL`   | Override URL for downloading emerge binary or archive artifacts.                                                                                                       | `none`             |                  |
| `EMERGE_RELEASES_URL`   | Override URL for querying emerge available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
