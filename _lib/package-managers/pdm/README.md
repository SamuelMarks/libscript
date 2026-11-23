# Pdm

**Tier**: `T1` (`_lib/package-managers/pdm/`) | **Capabilities**: `userland-package`

Bootstrap module for `pdm` (Modern Python package and dependency manager).

## Usage

Ensures the `pdm` executable is available. Relies on `pipx` or standard Python `pip`.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PDM_INSTALL_METHOD` | Installation strategy for pdm: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PDM_VERSION`        | Specific version of pdm to install.                                                                                                                   | `latest`           |                  |
| `PDM_DOWNLOAD_URL`   | Override URL for downloading pdm binary or archive artifacts.                                                                                         | `none`             |                  |
| `PDM_RELEASES_URL`   | Override URL for querying pdm available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
