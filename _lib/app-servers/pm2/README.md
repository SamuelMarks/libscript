# pm2

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `pm2` component (part of
`_app-servers`) within the LibScript ecosystem. Production process manager and cluster load balancer
for Node.js and polyglot applications.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **PM2**. It is designed to be
executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install pm2
libscript uninstall pm2
```

**Start / Stop (if configured as a background service):**

```sh
libscript start pm2
libscript stop pm2
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker pm2
```

_Note: On Unix environments, you can also use `./cli.sh install pm2`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default            | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `PM2_INSTALL_METHOD` | How to install pm2. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `PM2_VERSION`        | Specific version of pm2 to install.                                                                                                          | `latest`           | latest, lts      |
| `PM2_DOWNLOAD_URL`   | Override URL for downloading pm2 binary or archive artifacts.                                                                                | `none`             |                  |
| `PM2_RELEASES_URL`   | Override URL for querying pm2 available remote releases.                                                                                     | `none`             |                  |
| `PM2_LISTEN_PORT`    | TCP port on which the pm2 service listens.                                                                                                   | `9615`             |                  |

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
