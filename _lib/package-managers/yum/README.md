# yum

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `yum` component (part of
`_package-managers`) within the LibScript ecosystem. Legacy RHEL/CentOS Yellowdog Updater Modified
(yum) RPM package manager wrapper.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **YUM**. It is designed to be
executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install yum
libscript uninstall yum
```

**Start / Stop (if configured as a background service):**

```sh
libscript start yum
libscript stop yum
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker yum
```

_Note: On Unix environments, you can also use `./cli.sh install yum`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default  | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `YUM_INSTALL_METHOD` | How to install yum. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `YUM_VERSION`        | Specific version of yum to install.                                                                                                          | `latest` | latest, lts      |
| `YUM_DOWNLOAD_URL`   | Override URL for downloading yum binary or archive artifacts.                                                                                | `none`   |                  |
| `YUM_RELEASES_URL`   | Override URL for querying yum available remote releases.                                                                                     | `none`   |                  |

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
