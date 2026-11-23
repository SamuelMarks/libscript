# Pkgx

**Tier**: `T1` (`_lib/package-managers/pkgx/`) | **Capabilities**: `userland-package`

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

| Variable              | Description                                                                                                                                            | Default            | Aliases/Examples |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `PKGX_INSTALL_METHOD` | Installation strategy for pkgx: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `libscript_native` |                  |
| `PKGX_VERSION`        | Installation strategy for pkgx: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `latest`           |                  |
| `PKGX_DOWNLOAD_URL`   | Installation strategy for pkgx: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `none`             |                  |
| `PKGX_RELEASES_URL`   | Installation strategy for pkgx: 'libscript_native' installs into isolated versioned directories and 'system' delegates to the host OS package manager. | `none`             |                  |

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
