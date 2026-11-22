# couchdb

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `couchdb` component (part
of `_databases`) within the LibScript ecosystem. Seamless multi-master syncing document database
with an intuitive HTTP/JSON API and reliability focus.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Apache CouchDB**. It is
designed to be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install couchdb
libscript uninstall couchdb
```

**Start / Stop (if configured as a background service):**

```sh
libscript start couchdb
libscript stop couchdb
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker couchdb
```

_Note: On Unix environments, you can also use `./cli.sh install couchdb`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                 | Description                                                                                                                                      | Default  | Aliases/Examples |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `COUCHDB_INSTALL_METHOD` | How to install couchdb. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `COUCHDB_VERSION`        | Specific version of couchdb to install.                                                                                                          | `latest` | latest, lts      |
| `COUCHDB_DOWNLOAD_URL`   | Override URL for downloading couchdb binary or archive artifacts.                                                                                | `none`   |                  |
| `COUCHDB_RELEASES_URL`   | Override URL for querying couchdb available remote releases.                                                                                     | `none`   |                  |
| `COUCHDB_LISTEN_PORT`    | TCP port on which the couchdb service listens.                                                                                                   | `5984`   |                  |

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
