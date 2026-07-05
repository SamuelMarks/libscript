# Brew

Homebrew is a free and open-source software package management libscript_native that simplifies the
installation of software on macOS and Linux. It builds packages from source and provides
pre-compiled binaries, making it easy to manage dependencies and development tools.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`.

Homebrew can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud,
etc.).

## Usage

You can manage Homebrew using libscript with the following commands:

- **Install**: `libscript install brew`
- **Uninstall**: `libscript uninstall brew`
- **Start**: `libscript start brew`
- **Stop**: `libscript stop brew`
- **Package**: `libscript package brew`

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `brew` versions natively by default (`BREW_INSTALL_METHOD=libscript_native`),
ensuring isolated installations without polluting global system paths. You can override this to use
`system`, `mise`, `asdf`, `pkgx`, or `vfox` if preferred.

Libscript manages brew versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/brew/<version>`.
