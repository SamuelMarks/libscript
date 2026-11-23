# Guix

**Tier**: `T1` (`_lib/package-managers/guix/`) | **Capabilities**: `userland-package`

Bootstrap module for the `guix` (GNU Guix) package manager.

## Usage

Downloads and installs the official `guix-install.sh` script non-interactively. Requires `sudo`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `GUIX_INSTALL_METHOD` | Installation strategy for guix: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `GUIX_VERSION`        | Specific version of guix to install.                                                                                                                   | `latest`           |                  |
| `GUIX_DOWNLOAD_URL`   | Override URL for downloading guix binary or archive artifacts.                                                                                         | `none`             |                  |
| `GUIX_RELEASES_URL`   | Override URL for querying guix available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
