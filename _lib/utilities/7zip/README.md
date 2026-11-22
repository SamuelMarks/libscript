# 7-Zip

## Usage

_Note: libscript manages versions natively for this component._

This document describes **7zip (7-Zip)**, a highly efficient, open-source file archiver known for
its high compression ratio and wide format support.

7zip works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from
the global version manager `libscript`. It acts as an essential foundational tool and can be used by
libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) that require archive
extraction or compression.

You can install, start, stop, package, and uninstall 7zip using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install 7zip

./cli.sh install 7zip

./libscript.sh start 7zip
./cli.sh start 7zip

./libscript.sh stop 7zip
./cli.sh stop 7zip

./libscript.sh package-as docker 7zip
./cli.sh package-as docker 7zip

./libscript.sh uninstall 7zip
./cli.sh uninstall 7zip
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install 7zip

:: Local CLI
cli.cmd install 7zip

:: Start and Stop
libscript.cmd start 7zip
cli.cmd start 7zip

libscript.cmd stop 7zip
cli.cmd stop 7zip

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi 7zip
cli.cmd package-as msi 7zip

:: Uninstall
libscript.cmd uninstall 7zip
cli.cmd uninstall 7zip
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                                                                              | Default  | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `SEVENZIP_VERSION`        | Specific version of 7zip to install.                                                                                                                                     | `latest` |                  |
| `SEVENZIP_INSTALL_METHOD` | How to install SEVENZIP. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system` |                  |
| `SEVENZIP_DOWNLOAD_URL`   | Override URL for downloading 7zip binary or archive artifacts.                                                                                                           | `none`   |                  |
| `SEVENZIP_RELEASES_URL`   | Override URL for querying 7zip available remote releases.                                                                                                                | `none`   |                  |

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
