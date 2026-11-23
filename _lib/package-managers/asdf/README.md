# Asdf

**Tier**: `T1` (`_lib/package-managers/asdf/`) | **Capabilities**: `userland-package`

Bootstrap module for the `asdf` universal version manager.

## Usage

Clones and installs `asdf` to `~/.asdf`. Requires manual sourcing in bash/zsh profiles by the user
for persistence.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `ASDF_INSTALL_METHOD` | Installation strategy for asdf: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `ASDF_VERSION`        | Installation strategy for asdf: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `latest`           |                  |
| `ASDF_DOWNLOAD_URL`   | Installation strategy for asdf: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `none`             |                  |
| `ASDF_RELEASES_URL`   | Installation strategy for asdf: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
