Scoop
=====

## Usage
This document describes the **Scoop** bootstrap component within the LibScript ecosystem. Scoop is a command-line installer for Windows that eliminates permission popup windows and hides GUI wizard dialogs.

The Scoop component functions as a **local version manager** (similar to rvm, nvm, pyenv, uv) for managing Windows tools, while also being capable of being invoked directly from the **global version manager**, `libscript`. Through this capability, Scoop is heavily used by `libscript` on Windows platforms to resolve dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage
You can install, start, stop, package, and uninstall scoop using the global `libscript` command or the local CLI.

**Unix (Linux/macOS):**
```sh

./libscript.sh install scoop

./cli.sh install scoop

./libscript.sh start scoop
./cli.sh start scoop

./libscript.sh stop scoop
./cli.sh stop scoop

./libscript.sh package_as docker scoop
./cli.sh package_as docker scoop

./libscript.sh uninstall scoop
./cli.sh uninstall scoop
```

**Windows:**
```cmd
:: Global Orchestrator
libscript.cmd install scoop

:: Local CLI
cli.cmd install scoop

:: Start and Stop
libscript.cmd start scoop
cli.cmd start scoop

libscript.cmd stop scoop
cli.cmd stop scoop

:: Package (e.g., as MSI installer)
libscript.cmd package_as msi scoop
cli.cmd package_as msi scoop

:: Uninstall
libscript.cmd uninstall scoop
cli.cmd uninstall scoop
```

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
