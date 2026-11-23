# Pacman

**Tier**: `T1` (`_lib/package-managers/pacman/`) | **Capabilities**: `userland-package`

Bootstrap module for the `pacman` package manager.

## Usage

This module ensures `pacman` is available and updated. Since `pacman` is natively integrated into
its corresponding Linux distributions, this typically just ensures the package index is up-to-date.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default  | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PACMAN_INSTALL_METHOD` | Installation strategy for pacman: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `PACMAN_VERSION`        | Specific version of pacman to install.                                                                                                                   | `latest` |                  |
| `PACMAN_DOWNLOAD_URL`   | Override URL for downloading pacman binary or archive artifacts.                                                                                         | `none`   |                  |
| `PACMAN_RELEASES_URL`   | Override URL for querying pacman available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
