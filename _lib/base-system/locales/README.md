# locales

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `locales` component (part
of `_base-system`) within the LibScript ecosystem. POSIX and GNU C Library (glibc) system locale
definition compiler (localedef / locale-gen) and declarative locale staging.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **POSIX & glibc System
Locales**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install locales
libscript uninstall locales
```

**Start / Stop (if configured as a background service):**

```sh
libscript start locales
libscript stop locales
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker locales
```

_Note: On Unix environments, you can also use `./cli.sh install locales`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default                           | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------- | ---------------- |
| `LOCALES_INSTALL_METHOD` | How to install locales. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native`                |                  |
| `LOCALES_VERSION`        | Specific version of locales to install.                                                                                                          | `latest`                          | latest, stable   |
| `LOCALES_DOWNLOAD_URL`   | Override URL for downloading locales binary or archive artifacts.                                                                                | `none`                            |                  |
| `LOCALES_RELEASES_URL`   | Override URL for querying locales available remote releases.                                                                                     | `none`                            |                  |
| `LOCALES_DEFAULT`        | Default LANG system locale staged into /etc/locale.conf when provisioning a target sysroot.                                                      | `en_US.UTF-8`                     |                  |
| `LOCALES_LIST`           | Comma-separated list of locale entries staged into /etc/locale.gen when provisioning a target sysroot.                                           | `en_US.UTF-8 UTF-8,C.UTF-8 UTF-8` |                  |

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
