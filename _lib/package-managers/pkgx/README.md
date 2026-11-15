# Pkgx

## Usage

This document describes **pkgx**, a blazing-fast, standalone, and cross-platform package manager
that runs anything.

pkgx works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. Additionally, it can be used by libscript to securely and
reliably build bigger stacks (like WordPress, Open edX, Nextcloud, etc.).

You can install, start, stop, package, and uninstall pkgx using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install pkgx

./cli.sh install pkgx

./libscript.sh start pkgx
./cli.sh start pkgx

./libscript.sh stop pkgx
./cli.sh stop pkgx

./libscript.sh package-as docker pkgx
./cli.sh package-as docker pkgx

./libscript.sh uninstall pkgx
./cli.sh uninstall pkgx
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install pkgx

:: Local CLI
cli.cmd install pkgx

:: Start and Stop
libscript.cmd start pkgx
cli.cmd start pkgx

libscript.cmd stop pkgx
cli.cmd stop pkgx

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi pkgx
cli.cmd package-as msi pkgx

:: Uninstall
libscript.cmd uninstall pkgx
cli.cmd uninstall pkgx
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                                          | Default            | Aliases/Examples |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PKGX_INSTALL_METHOD` | How to install PKGX. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `PKGX_VERSION`        | Specific version of pkgx to install.                                                                                                                                 | `latest`           |                  |
| `PKGX_DOWNLOAD_URL`   | Override URL for downloading pkgx binary or archive artifacts.                                                                                                       | `none`             |                  |
| `PKGX_RELEASES_URL`   | Override URL for querying pkgx available remote releases.                                                                                                            | `none`             |                  |

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
