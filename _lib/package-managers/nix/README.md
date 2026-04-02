Nix
===

Nix is a powerful package manager for Linux and other Unix systems that makes package management reliable and reproducible. It provides atomic upgrades and rollbacks, side-by-side installation of multiple versions of a package, multi-user package management, and easy setup of build environments.

## Integration with Libscript
It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`.

Nix can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can manage Nix using libscript with the following commands:

- **Install**: `libscript install nix`
- **Uninstall**: `libscript uninstall nix`
- **Start**: `libscript start nix`
- **Stop**: `libscript stop nix`
- **Package**: `libscript package nix`

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
