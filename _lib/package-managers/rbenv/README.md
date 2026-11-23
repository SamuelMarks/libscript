# Rbenv

**Tier**: `T1` (`_lib/package-managers/rbenv/`) | **Capabilities**: `userland-package`

Bootstrap module for the `rbenv` package manager.

## Usage

Ensures the `rbenv` executable is available. This relies on the core language toolchain appropriate
for the tool.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                             | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `RBENV_INSTALL_METHOD` | Installation strategy for rbenv: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `RBENV_VERSION`        | Specific version of rbenv to install.                                                                                                                   | `latest`           |                  |
| `RBENV_DOWNLOAD_URL`   | Override URL for downloading rbenv binary or archive artifacts.                                                                                         | `none`             |                  |
| `RBENV_RELEASES_URL`   | Override URL for querying rbenv available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
