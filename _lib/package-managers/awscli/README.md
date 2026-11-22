# awscli

Provides bootstrap definitions and wrappers for installing the AWS CLI natively via OS package
managers or official installers.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                                            | Default            | Aliases/Examples |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `AWSCLI_INSTALL_METHOD` | How to install AWSCLI. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `AWSCLI_VERSION`        | Version of AWS CLI to install                                                                                                                                          | `latest`           |                  |
| `AWSCLI_DOWNLOAD_URL`   | Override URL for downloading awscli binary or archive artifacts.                                                                                                       | `none`             |                  |
| `AWSCLI_RELEASES_URL`   | Override URL for querying awscli available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
