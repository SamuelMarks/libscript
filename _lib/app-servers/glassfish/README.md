# glassfish

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `glassfish` component
(part of `_app-servers`) within the LibScript ecosystem. Eclipse Foundation open-source Jakarta EE
compatible enterprise application server.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Eclipse GlassFish**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install glassfish
libscript uninstall glassfish
```

**Start / Stop (if configured as a background service):**

```sh
libscript start glassfish
libscript stop glassfish
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker glassfish
```

_Note: On Unix environments, you can also use `./cli.sh install glassfish`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `GLASSFISH_INSTALL_METHOD` | How to install glassfish. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `GLASSFISH_VERSION`        | Specific version of glassfish to install.                                                                                                          | `latest`           | latest, lts      |
| `GLASSFISH_DOWNLOAD_URL`   | Override URL for downloading glassfish binary or archive artifacts.                                                                                | `none`             |                  |
| `GLASSFISH_RELEASES_URL`   | Override URL for querying glassfish available remote releases.                                                                                     | `none`             |                  |
| `GLASSFISH_LISTEN_PORT`    | TCP port on which the glassfish service listens.                                                                                                   | `8080`             |                  |

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
