# Stack

**Tier**: `T1` (`_lib/package-managers/stack/`) | **Capabilities**: `userland-package`

Bootstrap module for the `stack` package manager.

## Usage

Ensures the `stack` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `STACK_INSTALL_METHOD` | Installation strategy for stack: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `STACK_VERSION`        | Specific version of stack to install.                                                                                                                   | `latest`           |                  |
| `STACK_DOWNLOAD_URL`   | Override URL for downloading stack binary or archive artifacts.                                                                                         | `none`             |                  |
| `STACK_RELEASES_URL`   | Override URL for querying stack available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
