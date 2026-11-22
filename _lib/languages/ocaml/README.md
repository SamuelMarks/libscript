# ocaml

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `ocaml` component (part of
`_languages`) within the LibScript ecosystem. Industrial-strength functional, imperative, and
object-oriented programming language with static type inference.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **OCaml**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install ocaml
libscript uninstall ocaml
```

**Start / Stop (if configured as a background service):**

```sh
libscript start ocaml
libscript stop ocaml
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker ocaml
```

_Note: On Unix environments, you can also use `./cli.sh install ocaml`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default  | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `OCAML_INSTALL_METHOD` | How to install ocaml. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `OCAML_VERSION`        | Specific version of ocaml to install.                                                                                                          | `latest` | latest, lts      |
| `OCAML_DOWNLOAD_URL`   | Override URL for downloading ocaml binary or archive artifacts.                                                                                | `none`   |                  |
| `OCAML_RELEASES_URL`   | Override URL for querying ocaml available remote releases.                                                                                     | `none`   |                  |

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
