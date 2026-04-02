Kubernetes K0S
==============

## Purpose & Current State
**Purpose**: This document provides context and technical details for the `kubernetes_k0s` component within the LibScript ecosystem. This component manages **k0s**, a zero-friction Kubernetes distribution.

## Usage
This directory contains the scripts to interact with `kubernetes_k0s`. It is designed to be executed via the global `libscript` command or directly via local CLI scripts.

## Usage
You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**
```sh
libscript install kubernetes_k0s 
```

**Start:**
```sh
libscript start kubernetes_k0s
```

**Stop:**
```sh
libscript stop kubernetes_k0s
```

**Uninstall:**
```sh
libscript uninstall kubernetes_k0s
```

**Package:**
```sh
libscript package_as docker kubernetes_k0s

```

## Configuration Options
The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before running the setup script.

| Variable | Description | Default | Aliases |
|----------|-------------|---------|---------|
| `DEST` | Destination (working directory) | `none` | `` |
| `VARS` | Key/value in JSON format (as an escaped string) | `none` | `` |
| `LIBSCRIPT_GLOBAL_INSTALL_METHOD` | Global override for how software should be installed across all systems (e.g. system package manager vs downloaded binaries/from-source). | `system` | `` |
| `LIBSCRIPT_WINDOWS_PKG_MGR` | Global package manager override for Windows targets (e.g. winget, choco). | `winget` | `` |
| `LIBSCRIPT_LISTEN_PORT` | Global port to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_ADDRESS` | Global address to listen on | `none` | `` |
| `LIBSCRIPT_LISTEN_SOCKET` | Global unix socket to listen on | `none` | `` |
| `KUBERNETES_K0S_LISTEN_PORT` | Port for KUBERNETES_K0S to listen on | `none` | `` |
| `KUBERNETES_K0S_LISTEN_ADDRESS` | Address for KUBERNETES_K0S to listen on | `none` | `` |
| `KUBERNETES_K0S_LISTEN_SOCKET` | Unix socket for KUBERNETES_K0S to listen on | `none` | `` |

## Architecture
- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables
See `vars.schema.json` for details on available variables.

## Platform Support
- Linux
- macOS
- Windows
