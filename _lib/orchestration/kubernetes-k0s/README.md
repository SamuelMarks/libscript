# Kubernetes K0S

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `kubernetes-k0s` component
within the LibScript ecolibscript_native. This component manages **k0s**, a zero-friction Kubernetes
distribution.

## Usage

This directory contains the scripts to interact with `kubernetes-k0s`. It is designed to be executed
via the global `libscript` command or directly via local CLI scripts.

You can install, start, stop, uninstall, and package this component using `libscript`.

**Install:**

```sh
libscript install kubernetes-k0s
```

**Start:**

```sh
libscript start kubernetes-k0s
```

**Stop:**

```sh
libscript stop kubernetes-k0s
```

**Uninstall:**

```sh
libscript uninstall kubernetes-k0s
```

**Package:**

```sh
libscript package-as docker kubernetes-k0s

```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                    | Default            | Aliases/Examples |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `KUBERNETES_K0S_VERSION`        | Specific version of k0s to install                                                                                                                                             | `latest`           |                  |
| `KUBERNETES_K0S_DEST`           | Destination (working directory)                                                                                                                                                | `none`             |                  |
| `KUBERNETES_K0S_VARS`           | Key/value in JSON format (as an escaped string)                                                                                                                                | `none`             |                  |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                                       | `none`             |                  |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                                    | `none`             |                  |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                                | `none`             |                  |
| `KUBERNETES_K0S_LISTEN_PORT`    | Port for KUBERNETES_K0S to listen on                                                                                                                                           | `none`             |                  |
| `KUBERNETES_K0S_LISTEN_ADDRESS` | Address for KUBERNETES_K0S to listen on                                                                                                                                        | `none`             |                  |
| `KUBERNETES_K0S_LISTEN_SOCKET`  | Unix socket for KUBERNETES_K0S to listen on                                                                                                                                    | `none`             |                  |
| `KUBERNETES_K0S_INSTALL_METHOD` | How to install KUBERNETES K0S. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, 'mise', 'asdf', 'pkgx', or 'vfox' defers to third-party tools. | `libscript_native` |                  |
| `KUBERNETES_K0S_DOWNLOAD_URL`   | Override URL for downloading kubernetes-k0s binary or archive artifacts.                                                                                                       | `none`             |                  |
| `KUBERNETES_K0S_RELEASES_URL`   | Override URL for querying kubernetes-k0s available remote releases.                                                                                                            | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
