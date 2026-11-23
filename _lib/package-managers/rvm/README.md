# Rvm

**Tier**: `T1` (`_lib/package-managers/rvm/`) | **Capabilities**: `userland-package`

Bootstrap module for the `rvm` package manager.

## Usage

Ensures the `rvm` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RVM_INSTALL_METHOD` | Installation strategy for rvm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `RVM_VERSION`        | Specific version of rvm to install.                                                                                                                   | `latest`           |                  |
| `RVM_DOWNLOAD_URL`   | Override URL for downloading rvm binary or archive artifacts.                                                                                         | `none`             |                  |
| `RVM_RELEASES_URL`   | Override URL for querying rvm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
