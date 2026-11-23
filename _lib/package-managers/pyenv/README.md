# Pyenv

**Tier**: `T1` (`_lib/package-managers/pyenv/`) | **Capabilities**: `userland-package`

Bootstrap module for `pyenv` (Python Version Manager).

## Usage

Ensures the `pyenv` executable/shell function is available. It installs `pyenv` on UNIX-like
systems, and `pyenv-win` on Windows.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PYENV_INSTALL_METHOD` | Installation strategy for pyenv: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PYENV_VERSION`        | Specific version of pyenv to install.                                                                                                                   | `latest`           |                  |
| `PYENV_DOWNLOAD_URL`   | Override URL for downloading pyenv binary or archive artifacts.                                                                                         | `none`             |                  |
| `PYENV_RELEASES_URL`   | Override URL for querying pyenv available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
