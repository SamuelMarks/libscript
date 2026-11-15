# Apache Mesos (`_lib/orchestration/mesos`)

## Overview

Standalone Version Manager for **Apache Mesos** (`mesos`, `mesos-master`, `mesos-agent`,
`mesos-local`, `mesos-execute`, `mesos-resolve`). Manages two-level cluster resource scheduling,
replicated log quorum leader election via ZooKeeper (`zk://127.0.0.1:2181/mesos`), and containerizer
execution (`docker,mesos` and native LibScript sandboxes).

## Usage

```sh
./libscript.sh ls-remote mesos
./libscript.sh install mesos 1.11.0
./libscript.sh use mesos 1.11.0
./libscript.sh start mesos
./libscript.sh status mesos
./libscript.sh logs mesos
./libscript.sh test mesos
./libscript.sh stop mesos
./libscript.sh uninstall mesos 1.11.0
```

```cmd
libscript.cmd install mesos 1.11.0
libscript.cmd start mesos
libscript.cmd status mesos
libscript.cmd test mesos
```

## Configuration

| Variable               | Description                                                   | Default                     |
| :--------------------- | :------------------------------------------------------------ | :-------------------------- |
| `MESOS_VERSION`        | Specific version of Apache Mesos to install.                  | `1.11.0`                    |
| `MESOS_INSTALL_METHOD` | How to install Apache Mesos (`libscript_native` or `system`). | `libscript_native`          |
| `MESOS_ROLE`           | Operational role (`master`, `agent`, or `local`).             | `local`                     |
| `MESOS_MASTER_PORT`    | Mesos Master HTTP/Protobuf port.                              | `5050`                      |
| `MESOS_AGENT_PORT`     | Mesos Agent HTTP/Protobuf port.                               | `5051`                      |
| `MESOS_ZK_URL`         | ZooKeeper URI for leader election.                            | `zk://127.0.0.1:2181/mesos` |
| `MESOS_QUORUM`         | Replicated log quorum size.                                   | `1`                         |
| `MESOS_WORK_DIR`       | Directory for replicated log and agent sandboxes.             | `/var/lib/mesos`            |
| `MESOS_CONTAINERIZERS` | Enabled Mesos containerizers.                                 | `docker,mesos`              |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                                      | Default                     | Aliases/Examples |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------- | --------------------------- | ---------------- |
| `MESOS_VERSION`        | Specific version of Apache Mesos to install.                                                                     | `1.11.0`                    | latest, stable   |
| `MESOS_INSTALL_METHOD` | How to install Apache Mesos ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages). | `libscript_native`          |                  |
| `MESOS_ROLE`           | Operational role of this Mesos node ('master', 'agent', or 'local' combined master+agent).                       | `local`                     |                  |
| `MESOS_MASTER_PORT`    | TCP port on which the Mesos Master HTTP/Protobuf endpoint listens.                                               | `5050`                      |                  |
| `MESOS_AGENT_PORT`     | TCP port on which the Mesos Agent HTTP/Protobuf endpoint listens.                                                | `5051`                      |                  |
| `MESOS_ZK_URL`         | ZooKeeper connection URI for Mesos master leader election and agent discovery.                                   | `zk://127.0.0.1:2181/mesos` |                  |
| `MESOS_QUORUM`         | Minimum size of the replicated log quorum required for Mesos master leader election.                             | `1`                         |                  |
| `MESOS_WORK_DIR`       | Filesystem directory path for Mesos master replicated log and agent task sandboxes.                              | `/var/lib/mesos`            |                  |
| `MESOS_CONTAINERIZERS` | Comma-separated list of enabled Mesos containerizers (e.g. 'docker,mesos').                                      | `docker,mesos`              |                  |
| `MESOS_HOME`           | Filesystem directory or path configuration for mesos (MESOS_HOME).                                               | `none`                      |                  |
| `MESOS_MASTER`         | Configuration variable MESOS_MASTER for mesos.                                                                   | `none`                      |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
