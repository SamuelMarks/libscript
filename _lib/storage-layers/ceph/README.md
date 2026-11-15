# ceph

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `ceph` component (part of
`_storage-layers`) within the LibScript ecosystem. Unified distributed storage cluster providing
RADOS object, RBD block, and CephFS file storage.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **Ceph**. It is designed to
be executed via the global `libscript.sh` router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install ceph
libscript uninstall ceph
```

**Start / Stop (if configured as a background service):**

```sh
libscript start ceph
libscript stop ceph
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker ceph
```

_Note: On Unix environments, you can also use `./cli.sh install ceph`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable              | Description                                                                                                                                   | Default  | Aliases/Examples |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `CEPH_INSTALL_METHOD` | How to install ceph. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `system` |                  |
| `CEPH_VERSION`        | Specific version of ceph to install.                                                                                                          | `latest` | latest, lts      |
| `CEPH_DOWNLOAD_URL`   | Override URL for downloading ceph binary or archive artifacts.                                                                                | `none`   |                  |
| `CEPH_RELEASES_URL`   | Override URL for querying ceph available remote releases.                                                                                     | `none`   |                  |
| `CEPH_LISTEN_PORT`    | TCP port on which the ceph service listens.                                                                                                   | `6789`   |                  |

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
