# Homebrew

Homebrew is a free and open-source software package management system that simplifies the installation of software on macOS and Linux. It builds packages from source and provides pre-compiled binaries, making it easy to manage dependencies and development tools.

## Integration with Libscript

It works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`.

Homebrew can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can manage Homebrew using libscript with the following commands:

- **Install**: `libscript install brew`
- **Uninstall**: `libscript uninstall brew`
- **Start**: `libscript start brew`
- **Stop**: `libscript stop brew`
- **Package**: `libscript package brew`
