# Nodejs Server

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `nodejs` component within
the LibScript ecosystem. This component manages a **Node.js server** environment.

## Usage

This directory contains the scripts to interact with `nodejs`. It is designed to be executed via the
global `libscript` command or directly via local CLI scripts.

You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**

```sh
libscript install nodejs
```

**Start:**

```sh
libscript start nodejs
```

**Stop:**

```sh
libscript stop nodejs
```

**Uninstall:**

```sh
libscript uninstall nodejs
```

**Package:**

```sh
libscript package-as docker nodejs

```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                       | Description                                                                                                                                                                   | Default            | Aliases/Examples |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NODEJS_SERVER_DEST`           | Destination (working directory)                                                                                                                                               | `none`             |                  |
| `NODEJS_SERVER_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`        | Global port to listen on                                                                                                                                                      | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`     | Global address to listen on                                                                                                                                                   | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`      | Global unix socket to listen on                                                                                                                                               | `none`             |                  |
| `NODEJS_SERVER_LISTEN_PORT`    | Port for NODEJS to listen on                                                                                                                                                  | `none`             |                  |
| `NODEJS_SERVER_LISTEN_ADDRESS` | Address for NODEJS to listen on                                                                                                                                               | `none`             |                  |
| `NODEJS_SERVER_LISTEN_SOCKET`  | Unix socket for NODEJS to listen on                                                                                                                                           | `none`             |                  |
| `NODEJS_SERVER_INSTALL_METHOD` | How to install NODEJS SERVER. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `NODEJS_SERVER_DOWNLOAD_URL`   | Override URL for downloading nodejs-server binary or archive artifacts.                                                                                                       | `none`             |                  |
| `NODEJS_SERVER_RELEASES_URL`   | Override URL for querying nodejs-server available remote releases.                                                                                                            | `none`             |                  |
| `NODEJS_SERVER_VERSION`        | Specific version of nodejs-server to install (e.g., latest, lts, or exact version).                                                                                           | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
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
