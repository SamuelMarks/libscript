# Macports

Bootstrap module for the `macports` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                                              | Default            | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `MACPORTS_INSTALL_METHOD` | How to install MACPORTS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `MACPORTS_VERSION`        | Specific version of macports to install.                                                                                                                                 | `latest`           |                  |
| `MACPORTS_DOWNLOAD_URL`   | Override URL for downloading macports binary or archive artifacts.                                                                                                       | `none`             |                  |
| `MACPORTS_RELEASES_URL`   | Override URL for querying macports available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
