# Poetry

**Tier**: `T1` (`_lib/package-managers/poetry/`) | **Capabilities**: `userland-package`

Bootstrap script for [Poetry](https://python-poetry.org/), a tool for Python dependency management
and packaging. Requires Python 3 to be installed.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default  | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `POETRY_INSTALL_METHOD` | Installation strategy for poetry: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `system` |                  |
| `POETRY_HOME`           | Directory where Poetry will be installed. Defaults to ~/.local or %APPDATA%\pypoetry.                                                                    | `none`   |                  |
| `POETRY_VERSION`        | Specific version of Poetry to install.                                                                                                                   | `none`   |                  |
| `POETRY_DOWNLOAD_URL`   | Override URL for downloading poetry binary or archive artifacts.                                                                                         | `none`   |                  |
| `POETRY_RELEASES_URL`   | Override URL for querying poetry available remote releases.                                                                                              | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
