# Helm

**Tier**: `T1` (`_lib/package-managers/helm/`) | **Capabilities**: `userland-package`

Bootstrap module for the `helm` Kubernetes package manager.

## Usage

Installs the `helm` executable via its official get-helm-3 script.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `HELM_INSTALL_METHOD` | Installation strategy for helm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `HELM_VERSION`        | Specific version of helm to install.                                                                                                                   | `latest`           |                  |
| `HELM_DOWNLOAD_URL`   | Override URL for downloading helm binary or archive artifacts.                                                                                         | `none`             |                  |
| `HELM_RELEASES_URL`   | Override URL for querying helm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
