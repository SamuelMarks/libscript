# forgejo

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `forgejo` component (part
of `_git-servers`) within the LibScript ecosystem. Self-hosted lightweight community-governed
software forge supporting Git, CI/CD Actions, and packages.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Forgejo**. It is designed
to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install forgejo
libscript uninstall forgejo
```

**Start / Stop (if configured as a background service):**

```sh
libscript start forgejo
libscript stop forgejo
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker forgejo
```

_Note: On Unix environments, you can also use `./cli.sh install forgejo`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default            | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `FORGEJO_INSTALL_METHOD` | How to install forgejo. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `FORGEJO_VERSION`        | Specific version of forgejo to install.                                                                                                          | `latest`           | latest, lts      |
| `FORGEJO_DOWNLOAD_URL`   | Override URL for downloading forgejo binary or archive artifacts.                                                                                | `none`             |                  |
| `FORGEJO_RELEASES_URL`   | Override URL for querying forgejo available remote releases.                                                                                     | `none`             |                  |
| `FORGEJO_LISTEN_PORT`    | TCP port on which the forgejo service listens.                                                                                                   | `3000`             |                  |

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
