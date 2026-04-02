Choco
=====

## Usage
This document describes **Chocolatey (choco)**, a machine-level, command-line package manager and installer for Windows software. 

Chocolatey works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. Furthermore, it can be used by libscript as a foundational tool to build and provision bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall choco using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install choco

./cli.sh install choco

./libscript.sh start choco
./cli.sh start choco

./libscript.sh stop choco
./cli.sh stop choco

./libscript.sh package_as docker choco
./cli.sh package_as docker choco

./libscript.sh uninstall choco
./cli.sh uninstall choco
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install choco

:: Local CLI
cli.cmd install choco

:: Start and Stop
libscript.cmd start choco
cli.cmd start choco

libscript.cmd stop choco
cli.cmd stop choco

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi choco
cli.cmd package_as msi choco

:: Uninstall
libscript.cmd uninstall choco
cli.cmd uninstall choco
```

## Configuration
*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
