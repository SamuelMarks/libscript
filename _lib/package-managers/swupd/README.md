# Swupd

**Tier**: `T1` (`_lib/package-managers/swupd/`) | **Capabilities**: `userland-package`

Bootstrap module for `swupd` (Clear Linux OS package manager).

## Usage

Ensures the `swupd` executable is available. As this is an OS-level package manager for Clear Linux,
it cannot be reliably bootstrapped on other distributions or operating systems.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SWUPD_INSTALL_METHOD` | Installation strategy for swupd: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `SWUPD_VERSION`        | Specific version of swupd to install.                                                                                                                   | `latest`           |                  |
| `SWUPD_DOWNLOAD_URL`   | Override URL for downloading swupd binary or archive artifacts.                                                                                         | `none`             |                  |
| `SWUPD_RELEASES_URL`   | Override URL for querying swupd available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
