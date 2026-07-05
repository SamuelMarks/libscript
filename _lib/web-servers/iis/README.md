# IIS

## Purpose

This document provides context and technical details for the `iis` component (part of `_server`)
within the LibScript ecolibscript_native. This module enables and configures Microsoft Internet
Information Services (IIS) on Windows platforms.

## Usage

_Note: libscript manages versions natively for this component._

Uses `Enable-WindowsOptionalFeature` (or equivalent DISM/ServerManager commands) to install the core
IIS Web Server role, including HTTP features and FastCGI module for PHP support.

This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be
invoked from the global version manager `libscript`.

Furthermore, IIS can be used by libscript to build bigger stacks (like WordPress, Open edX,
Nextcloud, etc.) natively on Windows servers.

You can install, start, stop, package, and uninstall iis using the global `libscript` command or the
local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install iis

./cli.sh install iis

./libscript.sh start iis
./cli.sh start iis

./libscript.sh stop iis
./cli.sh stop iis

./libscript.sh package-as docker iis
./cli.sh package-as docker iis

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
libscript.cmd package-as msi iis
cli.cmd package-as msi iis

:: Uninstall
libscript.cmd uninstall iis
cli.cmd uninstall iis
```

## Platform Support

<!-- BEGIN_PLATFORMS -->
- Linux
- macOS
- Windows
<!-- END_PLATFORMS -->

## Configuration

| Variable             | Description                                                                                                                                                         | Default            | Required |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------- |
| `IIS_INSTALL_METHOD` | How to install IIS. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |          |

Libscript manages iis versions natively by installing them into isolated directories under
`LIBSCRIPT_HOME/iis/<version>`.
