# Apache HTTPD

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `httpd` server component
within the LibScript ecolibscript_native. LibScript is a modular, zero-dependency shell-script
framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the scripts for managing the Apache HTTPD component. It works both as a
local version manager (similar to rvm, nvm, pyenv, uv) for precise HTTPD version control, and can be
invoked seamlessly from the global version manager `libscript`.

Furthermore, this component can be used by libscript to build bigger stacks (like WordPress, Open
edX, nextcloud, etc.), serving as a reliable web server foundation.

You can install, start, stop, package, and uninstall httpd using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install httpd

./cli.sh install httpd

./libscript.sh start httpd
./cli.sh start httpd

./libscript.sh stop httpd
./cli.sh stop httpd

./libscript.sh package-as docker httpd
./cli.sh package-as docker httpd

./libscript.sh uninstall httpd
./cli.sh uninstall httpd
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install httpd

:: Local CLI
cli.cmd install httpd

:: Start and Stop
libscript.cmd start httpd
cli.cmd start httpd

libscript.cmd stop httpd
cli.cmd stop httpd

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi httpd
cli.cmd package-as msi httpd

:: Uninstall
libscript.cmd uninstall httpd
cli.cmd uninstall httpd
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                           | Default           | Aliases/Examples |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ---------------- |
| `HTTPD_INSTALL_METHOD`          | How to install HTTPD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `system`          |                  |
| `HTTPD_VERSION`                 | Specific version of httpd to install. Can be a numeric version or an alias.                                                                                           | `latest`          | latest, stable   |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                              | `none`            |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                           | `none`            |                  |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                       | `none`            |                  |
| `HTTPD_LISTEN_PORT`             | Port for HTTPD to listen on                                                                                                                                           | `none`            |                  |
| `HTTPD_LISTEN_ADDRESS`          | Address for HTTPD to listen on                                                                                                                                        | `none`            |                  |
| `HTTPD_LISTEN_SOCKET`           | Unix socket for HTTPD to listen on                                                                                                                                    | `none`            |                  |
| `HTTPD_WWWROOT_NAME`            | The primary domain or server name (ServerName) for Apache to bind to.                                                                                                 | `none`            |                  |
| `HTTPD_WWWROOT_PATH`            | The absolute path to the DocumentRoot directory.                                                                                                                      | `none`            |                  |
| `HTTPD_WWWROOT_LISTEN`          | The HTTP port Apache should listen on (defaults to 80).                                                                                                               | `80`              |                  |
| `HTTPD_SERVICE_RUN_AS_USER`     | Windows local user account to run the Apache service under (leave empty for default).                                                                                 | `none`            |                  |
| `HTTPD_SERVICE_RUN_AS_PASSWORD` | Password for the Windows local user account (if applicable).                                                                                                          | `none`            |                  |
| `HTTPD_SERVICE_NAME`            | Custom name for the Windows Service (allows side-by-side installations).                                                                                              | `libscript_httpd` |                  |
| `HTTPD_LISTEN`                  | Address/port to listen on.                                                                                                                                            | `none`            |                  |
| `HTTPD_WWWROOT`                 | Web server root directory.                                                                                                                                            | `none`            |                  |
| `HTTPD_PHP_FPM_LISTEN`          | Listen address/socket for PHP-FPM.                                                                                                                                    | `none`            |                  |
| `HTTPD_SERVER_NAME`             | Name of the server (e.g., example.com).                                                                                                                               | `none`            |                  |
| `HTTPD_DOWNLOAD_URL`            | Override URL for downloading httpd binary or archive artifacts.                                                                                                       | `none`            |                  |
| `HTTPD_RELEASES_URL`            | Override URL for querying httpd available remote releases.                                                                                                            | `none`            |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
