Pkgx
====

## Usage
This document describes **pkgx**, a blazing-fast, standalone, and cross-platform package manager that runs anything.

pkgx works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Additionally, it can be used by libscript to securely and reliably build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall pkgx using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install pkgx

./cli.sh install pkgx

./libscript.sh start pkgx
./cli.sh start pkgx

./libscript.sh stop pkgx
./cli.sh stop pkgx

./libscript.sh package_as docker pkgx
./cli.sh package_as docker pkgx

./libscript.sh uninstall pkgx
./cli.sh uninstall pkgx
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install pkgx

:: Local CLI
cli.cmd install pkgx

:: Start and Stop
libscript.cmd start pkgx
cli.cmd start pkgx

libscript.cmd stop pkgx
cli.cmd stop pkgx

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi pkgx
cli.cmd package_as msi pkgx

:: Uninstall
libscript.cmd uninstall pkgx
cli.cmd uninstall pkgx
```

## Configuration
*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
