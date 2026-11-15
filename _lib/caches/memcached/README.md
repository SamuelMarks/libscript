# Memcached

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `memcached` component
(part of `_caches`) within the LibScript ecosystem. LibScript is a modular, zero-dependency
shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS,
and Windows.

## Usage

This directory contains the installation, configuration, and lifecycle management scripts for
**Memcached**.

Crucially, this component works both as a **local version manager** (similar to tools like `rvm`,
`nvm`, `pyenv`, or `uv`) for managing isolated instances of Memcached, and it can be invoked
seamlessly from the **global version manager**, `libscript`.

Furthermore, `libscript` can utilize this Memcached component as a foundational building block to
provision and build **bigger stacks** (such as WordPress, Django, Nextcloud, and more).

You can install, start, stop, package, and uninstall memcached using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh
./libscript.sh install memcached
./cli.sh install memcached

./libscript.sh start memcached
./cli.sh start memcached

./libscript.sh stop memcached
./cli.sh stop memcached

./libscript.sh package-as docker memcached
./cli.sh package-as docker memcached

./libscript.sh uninstall memcached
./cli.sh uninstall memcached
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install memcached

:: Local CLI
cli.cmd install memcached

:: Start and Stop
libscript.cmd start memcached
cli.cmd start memcached

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi memcached
cli.cmd package-as msi memcached

:: Uninstall
libscript.cmd uninstall memcached
cli.cmd uninstall memcached
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                         | Description                                                                                                                                                               | Default            | Aliases/Examples |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `MEMCACHED_VERSION`              | Specific version of memcached to install. Can be a numeric version or an alias.                                                                                           | `latest`           | latest, stable   |
| `MEMCACHED_INSTALL_METHOD`       | How to install MEMCACHED. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `LIBSCRIPT_LISTEN_PORT`          | Global port to listen on                                                                                                                                                  | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`       | Global address to listen on                                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`        | Global unix socket to listen on                                                                                                                                           | `none`             |                  |
| `MEMCACHED_LISTEN_PORT`          | Port for MEMCACHED to listen on                                                                                                                                           | `11211`            |                  |
| `MEMCACHED_PORT_CONFLICT_POLICY` | Policy if configured port is occupied: abort, auto-increment, or reuse                                                                                                    | `abort`            |                  |
| `MEMCACHED_LISTEN_ADDRESS`       | Address for MEMCACHED to listen on                                                                                                                                        | `none`             |                  |
| `MEMCACHED_LISTEN_SOCKET`        | Unix socket for MEMCACHED to listen on                                                                                                                                    | `none`             |                  |
| `MEMCACHED_DOWNLOAD_URL`         | Custom download URL for memcached binary or source archive                                                                                                                | `none`             |                  |
| `MEMCACHED_LISTEN`               | Listen endpoint (address:port or socket) for memcached.                                                                                                                   | `none`             |                  |
| `MEMCACHED_RELEASES_URL`         | Override URL for querying memcached available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
