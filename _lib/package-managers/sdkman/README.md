# Sdkman

Bootstrap script for [SDKMAN!](https://sdkman.io/), a tool for managing parallel versions of
multiple Software Development Kits on most Unix based libscript_natives.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SDKMAN_INSTALL_METHOD` | How to install SDKMAN. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `SDKMAN_DIR`            | Installation directory for SDKMAN!. Defaults to ~/.sdkman.                                                                                                             | `none`             |                  |
| `SDKMAN_VERSION`        | Specific version of sdkman to install.                                                                                                                                 | `latest`           |                  |
| `SDKMAN_DOWNLOAD_URL`   | Override URL for downloading sdkman binary or archive artifacts.                                                                                                       | `none`             |                  |
| `SDKMAN_RELEASES_URL`   | Override URL for querying sdkman available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
