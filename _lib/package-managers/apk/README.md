Apk
===

## Usage
This document describes the **apk** (Alpine Package Keeper) bootstrap component for the LibScript ecosystem. It handles the integration and management of the Alpine Linux package manager.

Designed for flexibility, it works both as a **local version manager** (similar to rvm, nvm, pyenv, uv) for `apk` environments and can be effortlessly invoked from the **global version manager**, `libscript`. As a foundational tool, `apk` is frequently used by `libscript` to provision system dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) on Alpine-based systems or containers.

## Usage
You can install, start, stop, package, and uninstall apk using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install apk

./cli.sh install apk

./libscript.sh start apk
./cli.sh start apk

./libscript.sh stop apk
./cli.sh stop apk

./libscript.sh package_as docker apk
./cli.sh package_as docker apk

./libscript.sh uninstall apk
./cli.sh uninstall apk
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install apk

:: Local CLI
cli.cmd install apk

:: Start and Stop
libscript.cmd start apk
cli.cmd start apk

libscript.cmd stop apk
cli.cmd stop apk

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi apk
cli.cmd package_as msi apk

:: Uninstall
libscript.cmd uninstall apk
cli.cmd uninstall apk
```

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
