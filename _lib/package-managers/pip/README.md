# Pip

**Tier**: `T1` (`_lib/package-managers/pip/`) | **Capabilities**: `userland-package`

Bootstrap module for the `pip` package manager.

## Usage

Ensures the `pip` executable is available. This relies on the core language toolchain (e.g.,
Python).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default  | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `PIP_INSTALL_METHOD` | Installation strategy for pip: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `PIP_VERSION`        | Specific version of pip to install.                                                                                                                   | `latest` |                  |
| `PIP_DOWNLOAD_URL`   | Override URL for downloading pip binary or archive artifacts.                                                                                         | `none`   |                  |
| `PIP_RELEASES_URL`   | Override URL for querying pip available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
