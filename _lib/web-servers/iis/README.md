# IIS

**Tier**: `T1` (`_lib/web-servers/iis/`) | **Capabilities**: `userland-package`, `service-daemon`

## Purpose

This document provides context and technical details for the `iis` component (part of
`_lib/web-servers`) within the LibScript ecosystem. This module enables and configures Microsoft
Internet Information Services (IIS) on Windows platforms.

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

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                           | Default            | Aliases/Examples |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `IIS_INSTALL_METHOD` | Installation strategy for iis: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `IIS_VERSION`        | Version of IIS to install                                                                                                                             | `latest`           |                  |
| `IIS_DOWNLOAD_URL`   | Override URL for downloading iis binary or archive artifacts.                                                                                         | `none`             |                  |
| `IIS_RELEASES_URL`   | Override URL for querying iis available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
