# Xbps

**Tier**: `T1` (`_lib/package-managers/xbps/`) | **Capabilities**: `userland-package`

Bootstrap module for the Void Linux `xbps` package manager.

## Usage

Ensures the `xbps-install` executable is available (usually built-in on Void Linux).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `XBPS_INSTALL_METHOD` | Installation strategy for xbps: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `XBPS_VERSION`        | Specific version of xbps to install.                                                                                                                   | `latest`           |                  |
| `XBPS_DOWNLOAD_URL`   | Override URL for downloading xbps binary or archive artifacts.                                                                                         | `none`             |                  |
| `XBPS_RELEASES_URL`   | Override URL for querying xbps available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
