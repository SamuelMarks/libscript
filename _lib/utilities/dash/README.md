# Dash

## Usage

_Note: libscript manages versions natively for this component._

This document describes **Dash**, a POSIX-compliant implementation of `/bin/sh` that aims to be as
small and efficient as possible.

Dash works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. It can also be seamlessly used by libscript as an underlying
dependency to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall dash using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install dash

./cli.sh install dash

./libscript.sh start dash
./cli.sh start dash

./libscript.sh stop dash
./cli.sh stop dash

./libscript.sh package-as docker dash
./cli.sh package-as docker dash

./libscript.sh uninstall dash
./cli.sh uninstall dash
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install dash

:: Local CLI
cli.cmd install dash

:: Start and Stop
libscript.cmd start dash
cli.cmd start dash

libscript.cmd stop dash
cli.cmd stop dash

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi dash
cli.cmd package-as msi dash

:: Uninstall
libscript.cmd uninstall dash
cli.cmd uninstall dash
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default  | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `DASH_INSTALL_METHOD` | How to install DASH. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `DASH_VERSION`        | Specific version of dash to install.                                                                                                                                 | `latest` |                  |
| `DASH_DOWNLOAD_URL`   | Override URL for downloading dash binary or archive artifacts.                                                                                                       | `none`   |                  |
| `DASH_RELEASES_URL`   | Override URL for querying dash available remote releases.                                                                                                            | `none`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
