# step-ca

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `step-ca` component (part
of `_security`) within the LibScript ecosystem. Private online X.509 and SSH certificate authority
server supporting automated ACME certificate issuance.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Smallstep step-ca**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install step-ca
libscript uninstall step-ca
```

**Start / Stop (if configured as a background service):**

```sh
libscript start step-ca
libscript stop step-ca
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker step-ca
```

_Note: On Unix environments, you can also use `./cli.sh install step-ca`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `STEP_CA_INSTALL_METHOD` | How to install step-ca. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `STEP_CA_VERSION`        | Specific version of step-ca to install.                                                                                                          | `latest`           | latest, lts      |
| `STEP_CA_DOWNLOAD_URL`   | Override URL for downloading step-ca binary or archive artifacts.                                                                                | `none`             |                  |
| `STEP_CA_RELEASES_URL`   | Override URL for querying step-ca available remote releases.                                                                                     | `none`             |                  |
| `STEP_CA_LISTEN_PORT`    | TCP port on which the step-ca service listens.                                                                                                   | `9000`             |                  |

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
