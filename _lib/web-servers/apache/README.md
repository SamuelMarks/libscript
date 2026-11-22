# apache

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `apache` component (part
of `_web-servers`) within the LibScript ecosystem. Apache HTTP Server (apachectl / apache2) modular,
cross-platform web server recipe.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Apache HTTP Server**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install apache
libscript uninstall apache
```

**Start / Stop (if configured as a background service):**

```sh
libscript start apache
libscript stop apache
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker apache
```

_Note: On Unix environments, you can also use `./cli.sh install apache`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default  | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `APACHE_INSTALL_METHOD` | How to install apache. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `APACHE_VERSION`        | Specific version of apache to install.                                                                                                          | `latest` | latest, lts      |
| `APACHE_DOWNLOAD_URL`   | Override URL for downloading apache binary or archive artifacts.                                                                                | `none`   |                  |
| `APACHE_RELEASES_URL`   | Override URL for querying apache available remote releases.                                                                                     | `none`   |                  |
| `APACHE_LISTEN_PORT`    | TCP port on which the apache service listens.                                                                                                   | `80`     |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
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
