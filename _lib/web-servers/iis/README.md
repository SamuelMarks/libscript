IIS
===

## Purpose
This document provides context and technical details for the `iis` component (part of `_server`) within the LibScript ecosystem. This module enables and configures Microsoft Internet Information Services (IIS) on Windows platforms.

## Usage
Uses `Enable-WindowsOptionalFeature` (or equivalent DISM/ServerManager commands) to install the core IIS Web Server role, including HTTP features and FastCGI module for PHP support.

This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. 

Furthermore, IIS can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) natively on Windows servers.

## Usage
You can install, start, stop, package, and uninstall iis using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install iis

./cli.sh install iis

./libscript.sh start iis
./cli.sh start iis

./libscript.sh stop iis
./cli.sh stop iis

./libscript.sh package_as docker iis
./cli.sh package_as docker iis

./libscript.sh uninstall iis
./cli.sh uninstall iis
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install iis

:: Local CLI
cli.cmd install iis

:: Start and Stop
libscript.cmd start iis
cli.cmd start iis

libscript.cmd stop iis
cli.cmd stop iis

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi iis
cli.cmd package_as msi iis

:: Uninstall
libscript.cmd uninstall iis
cli.cmd uninstall iis
```

## Platform Support
- Windows

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
