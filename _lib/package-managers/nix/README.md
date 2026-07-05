# Nix

Nix is a powerful package manager for Linux and other Unix libscript_natives that makes package
management reliable and reproducible. It provides atomic upgrades and rollbacks, side-by-side
installation of multiple versions of a package, multi-user package management, and easy setup of
build environments.

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

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `nix` versions natively by default (`NIX_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages nix versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/nix/<version>`.
