# Asdf

Bootstrap module for the `asdf` universal version manager.

## Usage

Clones and installs `asdf` to `~/.asdf`. Requires manual sourcing in bash/zsh profiles by the user
for persistence.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `ASDF_INSTALL_METHOD` | How to install ASDF. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `ASDF_VERSION`        | Specific version of asdf to install.                                                                                                                                 | `latest`           |                  |
| `ASDF_DOWNLOAD_URL`   | Override URL for downloading asdf binary or archive artifacts.                                                                                                       | `none`             |                  |
| `ASDF_RELEASES_URL`   | Override URL for querying asdf available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
