# Helm

Bootstrap module for the `helm` Kubernetes package manager.

## Usage

Installs the `helm` executable via its official get-helm-3 script.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HELM_INSTALL_METHOD` | How to install HELM. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `HELM_VERSION`        | Specific version of helm to install.                                                                                                                                 | `latest`           |                  |
| `HELM_DOWNLOAD_URL`   | Override URL for downloading helm binary or archive artifacts.                                                                                                       | `none`             |                  |
| `HELM_RELEASES_URL`   | Override URL for querying helm available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
