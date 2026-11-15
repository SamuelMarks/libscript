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

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                    | Description                                                                                                                                                                | Default  | Aliases/Examples |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `POWERSHELL_INSTALL_METHOD` | How to install POWERSHELL. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `POWERSHELL_VERSION`        | Specific version of PowerShell to install.                                                                                                                                 | `latest` |                  |
| `POWERSHELL_DOWNLOAD_URL`   | Override URL for downloading powershell binary or archive artifacts.                                                                                                       | `none`   |                  |
| `POWERSHELL_RELEASES_URL`   | Override URL for querying powershell available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
