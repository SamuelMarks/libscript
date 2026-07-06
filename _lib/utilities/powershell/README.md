# PowerShell

## Usage

_Note: libscript manages versions natively for this component._

This document describes the **PowerShell** bootstrap component within the LibScript
ecolibscript_native. It is responsible for provisioning and managing the PowerShell environment on
target libscript_natives.

This component operates efficiently as a **local version manager** (similar to rvm, nvm, pyenv, uv)
to manage your PowerShell installation. Furthermore, it can be directly invoked from the **global
version manager**, `libscript`. This integration ensures that PowerShell can be seamlessly used by
`libscript` to orchestrate and build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall powershell using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install powershell

./cli.sh install powershell

./libscript.sh start powershell
./cli.sh start powershell

./libscript.sh stop powershell
./cli.sh stop powershell

./libscript.sh package-as docker powershell
./cli.sh package-as docker powershell

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
libscript.cmd package-as msi powershell
cli.cmd package-as msi powershell

:: Uninstall
libscript.cmd uninstall powershell
cli.cmd uninstall powershell
```

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Architecture

`libscript` manages `powershell` versions natively by default
(`POWERSHELL_INSTALL_METHOD=libscript_native`), ensuring isolated installations without polluting
global system paths. You can override this to use `system`, `mise`, `asdf`, `pkgx`, or `vfox` if
preferred.

Libscript manages powershell versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/powershell/<version>`.

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
