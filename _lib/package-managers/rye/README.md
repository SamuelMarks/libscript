# Rye

**Tier**: `T1` (`_lib/package-managers/rye/`) | **Capabilities**: `userland-package`

Bootstrap module for the `rye` package manager.

## Usage

Ensures the `rye` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RYE_INSTALL_METHOD` | Installation strategy for rye: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `RYE_VERSION`        | Specific version of rye to install.                                                                                                                   | `latest`           |                  |
| `RYE_DOWNLOAD_URL`   | Override URL for downloading rye binary or archive artifacts.                                                                                         | `none`             |                  |
| `RYE_RELEASES_URL`   | Override URL for querying rye available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
