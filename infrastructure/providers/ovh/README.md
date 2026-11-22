# ovh

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `ovh` component (part of
`_cloud-providers`) within the LibScript ecosystem. OVHcloud CLI (ovhcloud) version manager and
declarative Public Cloud compute, vRack private network, security group, and DNS driver.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OVHcloud**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install ovh
libscript uninstall ovh
```

**Start / Stop (if configured as a background service):**

```sh
libscript start ovh
libscript stop ovh
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker ovh
```

_Note: On Unix environments, you can also use `./cli.sh install ovh`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                       | Default            | Aliases/Examples |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `OVH_INSTALL_METHOD` | How to install ovhcloud. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `OVH_VERSION`        | Specific version of ovhcloud to install.                                                                                                          | `latest`           | latest, stable   |
| `OVH_DOWNLOAD_URL`   | Override URL for downloading ovhcloud binary or archive artifacts.                                                                                | `none`             |                  |
| `OVH_RELEASES_URL`   | Override URL for querying ovhcloud available remote releases.                                                                                     | `none`             |                  |
| `OVH_REGION`         | Default OVHcloud Public Cloud region (e.g., GRA11, BHS5, SBG5).                                                                                   | `GRA11`            |                  |
| `OVH_PROJECT_ID`     | Default OVHcloud Public Cloud project serviceName / ID.                                                                                           | `none`             |                  |
| `OVH_FLAVOR`         | Default OVHcloud Public Cloud compute flavor.                                                                                                     | `d2-4`             |                  |

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
