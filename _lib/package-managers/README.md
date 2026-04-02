Package Managers
================

## Usage
This folder describes the **Bootstrap** components within the LibScript ecosystem. It contains installers and initializers for various fundamental package managers and shell environments. 

The bootstrap components function both as **local version managers** (similar to rvm, nvm, pyenv, uv) for their respective tools and can be invoked seamlessly from the **global version manager**, `libscript`. Because of this flexible architecture, the bootstrap utilities can be used by `libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) by ensuring the underlying host environment is correctly provisioned.

## Supported Bootstrap Managers
Currently supported tools in this folder include:
* `apk`: Alpine Linux package manager
* `brew`: Homebrew package manager
* `scoop`: Windows command-line installer
* `winget`: Windows Package Manager

*(Note: Additional components like PowerShell also exist within subdirectories).*

## Usage
You can install, start, stop, package, and uninstall package-managers using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install package-managers

./cli.sh install package-managers

./libscript.sh start package-managers
./cli.sh start package-managers

./libscript.sh stop package-managers
./cli.sh stop package-managers

./libscript.sh package_as docker package-managers
./cli.sh package_as docker package-managers

./libscript.sh uninstall package-managers
./cli.sh uninstall package-managers
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install package-managers

:: Local CLI
cli.cmd install package-managers

:: Start and Stop
libscript.cmd start package-managers
cli.cmd start package-managers

libscript.cmd stop package-managers
cli.cmd stop package-managers

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi package-managers
cli.cmd package_as msi package-managers

:: Uninstall
libscript.cmd uninstall package-managers
cli.cmd uninstall package-managers
```

## Platform Support
- Linux
- macOS
- Windows
