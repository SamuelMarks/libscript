# php-fpm

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `php-fpm` component (part
of `_app-servers`) within the LibScript ecosystem. PHP FastCGI Process Manager daemon with adaptive
process spawning for high-traffic PHP sites.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **PHP-FPM**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install php-fpm
libscript uninstall php-fpm
```

**Start / Stop (if configured as a background service):**

```sh
libscript start php-fpm
libscript stop php-fpm
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker php-fpm
```

_Note: On Unix environments, you can also use `./cli.sh install php-fpm`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `PHP_FPM_INSTALL_METHOD` | How to install php-fpm. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `PHP_FPM_VERSION`        | Specific version of php-fpm to install.                                                                                                          | `latest` | latest, lts      |
| `PHP_FPM_DOWNLOAD_URL`   | Override URL for downloading php-fpm binary or archive artifacts.                                                                                | `none`   |                  |
| `PHP_FPM_RELEASES_URL`   | Override URL for querying php-fpm available remote releases.                                                                                     | `none`   |                  |
| `PHP_FPM_LISTEN_PORT`    | TCP port on which the php-fpm service listens.                                                                                                   | `9000`   |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
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
