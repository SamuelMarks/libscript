Dash
====

## Usage
This document describes **Dash**, a POSIX-compliant implementation of `/bin/sh` that aims to be as small and efficient as possible.

Dash works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. It can also be seamlessly used by libscript as an underlying dependency to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall dash using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install dash

./cli.sh install dash

./libscript.sh start dash
./cli.sh start dash

./libscript.sh stop dash
./cli.sh stop dash

./libscript.sh package_as docker dash
./cli.sh package_as docker dash

./libscript.sh uninstall dash
./cli.sh uninstall dash
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install dash

:: Local CLI
cli.cmd install dash

:: Start and Stop
libscript.cmd start dash
cli.cmd start dash

libscript.cmd stop dash
cli.cmd stop dash

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi dash
cli.cmd package_as msi dash

:: Uninstall
libscript.cmd uninstall dash
cli.cmd uninstall dash
```

## Configuration
*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
