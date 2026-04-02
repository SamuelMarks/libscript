Winget
======

## Usage
This document describes **Winget**, the official Windows Package Manager CLI that allows users to discover, install, upgrade, remove, and configure applications on Windows 10 and Windows 11 computers.

Winget works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. It can additionally be used by libscript to build and deploy bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall winget using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install winget

./cli.sh install winget

./libscript.sh start winget
./cli.sh start winget

./libscript.sh stop winget
./cli.sh stop winget

./libscript.sh package_as docker winget
./cli.sh package_as docker winget

./libscript.sh uninstall winget
./cli.sh uninstall winget
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install winget

:: Local CLI
cli.cmd install winget

:: Start and Stop
libscript.cmd start winget
cli.cmd start winget

libscript.cmd stop winget
cli.cmd stop winget

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi winget
cli.cmd package_as msi winget

:: Uninstall
libscript.cmd uninstall winget
cli.cmd uninstall winget
```

## Configuration
*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
