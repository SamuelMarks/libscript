# Winget

**Tier**: `T1` (`_lib/package-managers/winget/`) | **Capabilities**: `userland-package`

## Usage

This document describes **Winget**, the official Windows Package Manager CLI that allows users to
discover, install, upgrade, remove, and configure applications on Windows 10 and Windows 11
computers.

Winget works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked
from the global version manager `libscript`. It can additionally be used by libscript to build and
deploy bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall winget using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install winget

./cli.sh install winget



./libscript.sh package-as docker winget
./cli.sh package-as docker winget

./libscript.sh uninstall winget
./cli.sh uninstall winget
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install winget

:: Local CLI
cli.cmd install winget

:: Start and Stop


:: Package (e.g., as MSI installer)
libscript.cmd package-as msi winget
cli.cmd package-as msi winget

:: Uninstall
libscript.cmd uninstall winget
cli.cmd uninstall winget
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                              | Default            | Aliases/Examples |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `WINGET_INSTALL_METHOD` | Installation strategy for winget: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `WINGET_VERSION`        | Specific version of winget to install.                                                                                                                   | `latest`           |                  |
| `WINGET_DOWNLOAD_URL`   | Override URL for downloading winget binary or archive artifacts.                                                                                         | `none`             |                  |
| `WINGET_RELEASES_URL`   | Override URL for querying winget available remote releases.                                                                                              | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
