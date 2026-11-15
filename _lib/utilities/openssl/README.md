# openssl

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `openssl` component (part
of `_utilities`) within the LibScript ecosystem. Full-featured commercial-grade TLS/SSL cryptography
library and openssl command-line toolkit.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenSSL**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install openssl
libscript uninstall openssl
```

**Start / Stop (if configured as a background service):**

```sh
libscript start openssl
libscript stop openssl
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker openssl
```

_Note: On Unix environments, you can also use `./cli.sh install openssl`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `OPENSSL_INSTALL_METHOD` | How to install openssl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OPENSSL_VERSION`        | Specific version of openssl to install.                                                                                                          | `latest` | latest, lts      |
| `OPENSSL_DOWNLOAD_URL`   | Override URL for downloading openssl binary or archive artifacts.                                                                                | `none`   |                  |
| `OPENSSL_RELEASES_URL`   | Override URL for querying openssl available remote releases.                                                                                     | `none`   |                  |

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
