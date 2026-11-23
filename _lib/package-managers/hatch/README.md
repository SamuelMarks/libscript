# Hatch

**Tier**: `T1` (`_lib/package-managers/hatch/`) | **Capabilities**: `userland-package`

Bootstrap module for `hatch` (Modern Python project manager).

## Usage

Ensures the `hatch` executable is available. Relies on `pipx` or standard Python `pip`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `HATCH_INSTALL_METHOD` | Installation strategy for hatch: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `HATCH_VERSION`        | Specific version of hatch to install.                                                                                                                   | `latest`           |                  |
| `HATCH_DOWNLOAD_URL`   | Override URL for downloading hatch binary or archive artifacts.                                                                                         | `none`             |                  |
| `HATCH_RELEASES_URL`   | Override URL for querying hatch available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
