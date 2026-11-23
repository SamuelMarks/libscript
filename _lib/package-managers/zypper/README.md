# Zypper

**Tier**: `T1` (`_lib/package-managers/zypper/`) | **Capabilities**: `userland-package`

Bootstrap module for the `zypper` package manager.

## Usage

This module ensures `zypper` is available and updated. Since `zypper` is natively integrated into
its corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ZYPPER_INSTALL_METHOD` | Installation strategy for zypper: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `ZYPPER_VERSION`        | Specific version of zypper to install.                                                                                                                   | `latest`           |                  |
| `ZYPPER_DOWNLOAD_URL`   | Override URL for downloading zypper binary or archive artifacts.                                                                                         | `none`             |                  |
| `ZYPPER_RELEASES_URL`   | Override URL for querying zypper available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
