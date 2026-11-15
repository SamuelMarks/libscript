# azure-cli

Provides bootstrap definitions and wrappers for installing the Azure CLI.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                                               | Default            | Aliases/Examples |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `AZURE_CLI_INSTALL_METHOD` | How to install AZURE_CLI. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `AZURE_CLI_VERSION`        | Version of Azure CLI to install                                                                                                                                           | `latest`           |                  |
| `AZURE_CLI_DOWNLOAD_URL`   | Override URL for downloading azure-cli binary or archive artifacts.                                                                                                       | `none`             |                  |
| `AZURE_CLI_RELEASES_URL`   | Override URL for querying azure-cli available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
