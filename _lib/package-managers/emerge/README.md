# Emerge

**Tier**: `T1` (`_lib/package-managers/emerge/`) | **Capabilities**: `userland-package`

Bootstrap module for the Gentoo `emerge` package manager.

## Usage

Ensures the `emerge` executable is available (usually built-in on Gentoo).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `EMERGE_INSTALL_METHOD` | Installation strategy for emerge: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `EMERGE_VERSION`        | Specific version of emerge to install.                                                                                                                   | `latest`           |                  |
| `EMERGE_DOWNLOAD_URL`   | Override URL for downloading emerge binary or archive artifacts.                                                                                         | `none`             |                  |
| `EMERGE_RELEASES_URL`   | Override URL for querying emerge available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
