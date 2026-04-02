7-Zip
=====

## Usage
This document describes **7zip (7-Zip)**, a highly efficient, open-source file archiver known for its high compression ratio and wide format support.

7zip works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. It acts as an essential foundational tool and can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) that require archive extraction or compression.

## Usage
You can install, start, stop, package, and uninstall 7zip using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install 7zip

./cli.sh install 7zip

./libscript.sh start 7zip
./cli.sh start 7zip

./libscript.sh stop 7zip
./cli.sh stop 7zip

./libscript.sh package_as docker 7zip
./cli.sh package_as docker 7zip

./libscript.sh uninstall 7zip
./cli.sh uninstall 7zip
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install 7zip

:: Local CLI
cli.cmd install 7zip

:: Start and Stop
libscript.cmd start 7zip
cli.cmd start 7zip

libscript.cmd stop 7zip
cli.cmd stop 7zip

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi 7zip
cli.cmd package_as msi 7zip

:: Uninstall
libscript.cmd uninstall 7zip
cli.cmd uninstall 7zip
```

## Configuration
*(There are currently no component-specific configuration tables or variables defined for this module.)*

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
