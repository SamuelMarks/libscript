# Scoop

## Usage

This document describes the **Scoop** bootstrap component within the LibScript ecolibscript_native.
Scoop is a command-line installer for Windows that eliminates permission popup windows and hides GUI
wizard dialogs.

The Scoop component functions as a **local version manager** (similar to rvm, nvm, pyenv, uv) for
managing Windows tools, while also being capable of being invoked directly from the **global version
manager**, `libscript`. Through this capability, Scoop is heavily used by `libscript` on Windows
platforms to resolve dependencies and build bigger stacks (like WordPress, Open edX, Nextcloud,
etc.).

You can install, start, stop, package, and uninstall scoop using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install scoop

./cli.sh install scoop

./libscript.sh start scoop
./cli.sh start scoop

./libscript.sh stop scoop
./cli.sh stop scoop

./libscript.sh package-as docker scoop
./cli.sh package-as docker scoop

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
libscript.cmd package-as msi scoop
cli.cmd package-as msi scoop

:: Uninstall
libscript.cmd uninstall scoop
cli.cmd uninstall scoop
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                                           | Default            | Aliases/Examples |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `SCOOP_INSTALL_METHOD` | How to install SCOOP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `SCOOP_VERSION`        | Specific version of scoop to install.                                                                                                                                 | `latest`           |                  |
| `SCOOP_DOWNLOAD_URL`   | Override URL for downloading scoop binary or archive artifacts.                                                                                                       | `none`             |                  |
| `SCOOP_RELEASES_URL`   | Override URL for querying scoop available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
