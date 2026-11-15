# cgit

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `cgit` component (part of
`_git-servers`) within the LibScript ecosystem. Hyperfast C CGI web frontend for Git repositories
with built-in caching.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **cgit**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install cgit
libscript uninstall cgit
```

**Start / Stop (if configured as a background service):**

```sh
libscript start cgit
libscript stop cgit
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker cgit
```

_Note: On Unix environments, you can also use `./cli.sh install cgit`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CGIT_INSTALL_METHOD` | How to install cgit. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `CGIT_VERSION`        | Specific version of cgit to install.                                                                                                          | `latest` | latest, lts      |
| `CGIT_DOWNLOAD_URL`   | Override URL for downloading cgit binary or archive artifacts.                                                                                | `none`   |                  |
| `CGIT_RELEASES_URL`   | Override URL for querying cgit available remote releases.                                                                                     | `none`   |                  |
| `CGIT_LISTEN_PORT`    | TCP port on which the cgit service listens.                                                                                                   | `80`     |                  |

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
