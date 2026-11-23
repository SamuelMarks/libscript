# Nvm

**Tier**: `T1` (`_lib/package-managers/nvm/`) | **Capabilities**: `userland-package`

Bootstrap module for `nvm` (Node Version Manager).

## Usage

Ensures the `nvm` executable/shell function is available. It installs `nvm` on UNIX-like systems,
and `nvm-windows` on Windows.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NVM_INSTALL_METHOD` | Installation strategy for nvm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `NVM_VERSION`        | Specific version of nvm to install.                                                                                                                   | `latest`           |                  |
| `NVM_DOWNLOAD_URL`   | Override URL for downloading nvm binary or archive artifacts.                                                                                         | `none`             |                  |
| `NVM_RELEASES_URL`   | Override URL for querying nvm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
