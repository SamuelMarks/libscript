# Apt

**Tier**: `T1` (`_lib/package-managers/apt/`) | **Capabilities**: `userland-package`

Bootstrap module for the `apt` package manager.

## Usage

This module ensures `apt` is available and updated. Since `apt` is natively integrated into its
corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `APT_INSTALL_METHOD` | Installation strategy for apt: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `APT_VERSION`        | Specific version of apt to install.                                                                                                                   | `latest`           |                  |
| `APT_DOWNLOAD_URL`   | Override URL for downloading apt binary or archive artifacts.                                                                                         | `none`             |                  |
| `APT_RELEASES_URL`   | Override URL for querying apt available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
