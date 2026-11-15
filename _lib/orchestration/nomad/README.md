# HashiCorp Nomad (`_lib/orchestration/nomad`)

## Overview

Standalone Version Manager for **HashiCorp Nomad** (`nomad`), orchestrating `service` and `batch`
workloads across containers, microVMs, and raw/isolated exec drivers.

## Usage

```sh
./libscript.sh ls-remote nomad
./libscript.sh install nomad 1.9.0
./libscript.sh use nomad 1.9.0
./libscript.sh start nomad
./libscript.sh status nomad
./libscript.sh test nomad
./libscript.sh stop nomad
./libscript.sh uninstall nomad 1.9.0
```

```cmd
libscript.cmd install nomad 1.9.0
libscript.cmd start nomad
libscript.cmd status nomad
libscript.cmd test nomad
```

## Configuration

| Variable               | Description                                            | Default            |
| :--------------------- | :----------------------------------------------------- | :----------------- |
| `NOMAD_VERSION`        | Specific version of HashiCorp Nomad to install.        | `1.9.0`            |
| `NOMAD_INSTALL_METHOD` | How to install Nomad (`libscript_native` or `system`). | `libscript_native` |
| `NOMAD_HTTP_PORT`      | Nomad HTTP API port.                                   | `4646`             |
| `NOMAD_DATA_DIR`       | Raft state and allocation sandbox directory.           | `/var/lib/nomad`   |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                         | Default            | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `NOMAD_VERSION`        | Specific version of HashiCorp Nomad to install.                                                                     | `1.9.0`            | latest, stable   |
| `NOMAD_INSTALL_METHOD` | How to install HashiCorp Nomad ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages). | `libscript_native` |                  |
| `NOMAD_HTTP_PORT`      | TCP port on which the Nomad HTTP API listens.                                                                       | `4646`             |                  |
| `NOMAD_DATA_DIR`       | Filesystem directory path for Nomad Raft state and allocation sandboxes.                                            | `/var/lib/nomad`   |                  |
| `NOMAD_ADDR`           | Configuration variable NOMAD_ADDR for nomad.                                                                        | `none`             |                  |
| `NOMAD_HOME`           | Filesystem directory or path configuration for nomad (NOMAD_HOME).                                                  | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
