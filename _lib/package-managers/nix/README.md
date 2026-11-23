# Nix

**Tier**: `T1` (`_lib/package-managers/nix/`) | **Capabilities**: `userland-package`

Nix is a powerful package manager for Linux and other Unix systems that makes package management
reliable and reproducible. It provides atomic upgrades and rollbacks, side-by-side installation of
multiple versions of a package, multi-user package management, and easy setup of build environments.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

Nix can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can manage Nix using libscript with the following commands:

- **Install**: `libscript install nix`
- **Uninstall**: `libscript uninstall nix`
- **Start**: `libscript start nix`
- **Stop**: `libscript stop nix`
- **Package**: `libscript package nix`

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NIX_INSTALL_METHOD` | Installation strategy for nix: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `NIX_VERSION`        | Specific version of nix to install.                                                                                                                   | `latest`           |                  |
| `NIX_DOWNLOAD_URL`   | Override URL for downloading nix binary or archive artifacts.                                                                                         | `none`             |                  |
| `NIX_RELEASES_URL`   | Override URL for querying nix available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
