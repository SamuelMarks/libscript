# tofu

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `tofu` component (part of
`_orchestration`) within the LibScript ecosystem. OpenTofu (tofu) Linux Foundation open-source
Infrastructure-as-Code CLI drop-in replacement for Terraform.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OpenTofu**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install tofu
libscript uninstall tofu
```

**Start / Stop (if configured as a background service):**

```sh
libscript start tofu
libscript stop tofu
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker tofu
```

_Note: On Unix environments, you can also use `./cli.sh install tofu`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default            | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `TOFU_INSTALL_METHOD` | How to install tofu. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `TOFU_VERSION`        | Specific version of tofu to install.                                                                                                          | `latest`           | latest, stable   |
| `TOFU_DOWNLOAD_URL`   | Override URL for downloading tofu binary or archive artifacts.                                                                                | `none`             |                  |
| `TOFU_RELEASES_URL`   | Override URL for querying tofu available remote releases.                                                                                     | `none`             |                  |

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
