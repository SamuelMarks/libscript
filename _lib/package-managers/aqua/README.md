# Aqua

**Tier**: `T1` (`_lib/package-managers/aqua/`) | **Capabilities**: `userland-package`

Bootstrap module for the `aqua` package manager.

## Usage

Ensures the `aqua` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `AQUA_INSTALL_METHOD` | Installation strategy for aqua: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `AQUA_VERSION`        | Specific version of aqua to install.                                                                                                                   | `latest`           |                  |
| `AQUA_DOWNLOAD_URL`   | Override URL for downloading aqua binary or archive artifacts.                                                                                         | `none`             |                  |
| `AQUA_RELEASES_URL`   | Override URL for querying aqua available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
