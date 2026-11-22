# neo4j

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `neo4j` component (part of
`_databases`) within the LibScript ecosystem. High-performance native graph database platform for
connected data and Cypher query workloads.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Neo4j**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install neo4j
libscript uninstall neo4j
```

**Start / Stop (if configured as a background service):**

```sh
libscript start neo4j
libscript stop neo4j
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker neo4j
```

_Note: On Unix environments, you can also use `./cli.sh install neo4j`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                                                    | Default            | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NEO4J_INSTALL_METHOD` | How to install neo4j. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `libscript_native` |                  |
| `NEO4J_VERSION`        | Specific version of neo4j to install.                                                                                                          | `latest`           | latest, lts      |
| `NEO4J_DOWNLOAD_URL`   | Override URL for downloading neo4j binary or archive artifacts.                                                                                | `none`             |                  |
| `NEO4J_RELEASES_URL`   | Override URL for querying neo4j available remote releases.                                                                                     | `none`             |                  |
| `NEO4J_LISTEN_PORT`    | TCP port on which the neo4j service listens.                                                                                                   | `7474`             |                  |

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
