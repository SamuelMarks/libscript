# sysctl

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `sysctl` component (part
of `_base-system`) within the LibScript ecosystem. Declarative kernel runtime parameter manager
(sysctl and /etc/sysctl.d drop-in configuration).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Kernel sysctl.d Parameter
Manager**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install sysctl
libscript uninstall sysctl
```

**Start / Stop (if configured as a background service):**

```sh
libscript start sysctl
libscript stop sysctl
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker sysctl
```

_Note: On Unix environments, you can also use `./cli.sh install sysctl`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                | Description                                                                                                                                     | Default                 | Aliases/Examples |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ---------------- |
| `SYSCTL_INSTALL_METHOD` | How to install sysctl. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`      |                  |
| `SYSCTL_VERSION`        | Specific version of sysctl to install.                                                                                                          | `latest`                | latest, stable   |
| `SYSCTL_DOWNLOAD_URL`   | Override URL for downloading sysctl binary or archive artifacts.                                                                                | `none`                  |                  |
| `SYSCTL_RELEASES_URL`   | Override URL for querying sysctl available remote releases.                                                                                     | `none`                  |                  |
| `SYSCTL_PARAMS`         | Comma-separated list of kernel key=value parameters rendered into /etc/sysctl.d/<SYSCTL_CONF_NAME>.                                             | `net.ipv4.ip_forward=1` |                  |
| `SYSCTL_CONF_NAME`      | Drop-in filename written under /etc/sysctl.d/ when staging declarative kernel parameters.                                                       | `99-libscript.conf`     |                  |

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
