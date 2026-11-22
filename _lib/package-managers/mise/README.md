# Mise

Bootstrap module for the `mise` package manager/tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MISE_INSTALL_METHOD` | How to install MISE. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `MISE_VERSION`        | Specific version of mise to install.                                                                                                                                 | `latest`           |                  |
| `MISE_DOWNLOAD_URL`   | Override URL for downloading mise binary or archive artifacts.                                                                                                       | `none`             |                  |
| `MISE_RELEASES_URL`   | Override URL for querying mise available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
