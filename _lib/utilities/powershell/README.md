PowerShell
==========

## Usage
This document describes the **PowerShell** bootstrap component within the LibScript ecosystem. It is responsible for provisioning and managing the PowerShell environment on target systems.

This component operates efficiently as a **local version manager** (similar to rvm, nvm, pyenv, uv) to manage your PowerShell installation. Furthermore, it can be directly invoked from the **global version manager**, `libscript`. This integration ensures that PowerShell can be seamlessly used by `libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall powershell using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install powershell

./cli.sh install powershell

./libscript.sh start powershell
./cli.sh start powershell

./libscript.sh stop powershell
./cli.sh stop powershell

./libscript.sh package_as docker powershell
./cli.sh package_as docker powershell

./libscript.sh uninstall powershell
./cli.sh uninstall powershell
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install powershell

:: Local CLI
cli.cmd install powershell

:: Start and Stop
libscript.cmd start powershell
cli.cmd start powershell

libscript.cmd stop powershell
cli.cmd stop powershell

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi powershell
cli.cmd package_as msi powershell

:: Uninstall
libscript.cmd uninstall powershell
cli.cmd uninstall powershell
```

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
