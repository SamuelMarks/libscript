# cdd-c

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `cdd-c` component (part of
`_toolchains`) within the LibScript ecosystem. Lossless C89 Concrete Syntax Tree (CST) parser and
4-pass lowering transformer (cdd-c-transform).

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **cdd-c C89 CST
Transformer**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install cdd-c
libscript uninstall cdd-c
```

**Start / Stop (if configured as a background service):**

```sh
libscript start cdd-c
libscript stop cdd-c
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker cdd-c
```

_Note: On Unix environments, you can also use `./cli.sh install cdd-c`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default       | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `CDD_C_INSTALL_METHOD` | How to install cdd-c. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `CDD_C_VERSION`        | Specific version of cdd-c to install.                                                                                                          | `latest`      | latest, lts      |
| `CDD_C_DOWNLOAD_URL`   | Override URL for downloading cdd-c binary or archive artifacts.                                                                                | `none`        |                  |
| `CDD_C_RELEASES_URL`   | Override URL for querying cdd-c available remote releases.                                                                                     | `none`        |                  |
| `CDD_C_REPO_DIR`       | Optional local checkout path for cdd-c when building standalone cdd-c-transform.                                                               | ``            |                  |

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
