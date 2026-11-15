# terraform

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `terraform` component
(part of `_orchestration`) within the LibScript ecosystem. HashiCorp Terraform declarative
Infrastructure-as-Code CLI for provisioning and managing cloud and on-prem resources.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **HashiCorp Terraform**. It
is designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install terraform
libscript uninstall terraform
```

**Start / Stop (if configured as a background service):**

```sh
libscript start terraform
libscript stop terraform
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker terraform
```

_Note: On Unix environments, you can also use `./cli.sh install terraform`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                                                        | Default            | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TERRAFORM_INSTALL_METHOD` | How to install terraform. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TERRAFORM_VERSION`        | Specific version of terraform to install.                                                                                                          | `latest`           | latest, stable   |
| `TERRAFORM_DOWNLOAD_URL`   | Override URL for downloading terraform binary or archive artifacts.                                                                                | `none`             |                  |
| `TERRAFORM_RELEASES_URL`   | Override URL for querying terraform available remote releases.                                                                                     | `none`             |                  |

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
