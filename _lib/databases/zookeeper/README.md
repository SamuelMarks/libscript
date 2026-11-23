# Apache ZooKeeper (`_lib/databases/zookeeper`)

**Tier**: `T1` (`_lib/databases/zookeeper/`) | **Capabilities**: `userland-package`,
`service-daemon`

## Overview

Standalone Version Manager for **Apache ZooKeeper** (`zookeeper`, `zkServer.sh`, `zkCli.sh`).
Provides centralized coordination, configuration management, `ruok`/`imok` four-letter health
checks, and quorum leader election state for Apache Mesos (`zk://127.0.0.1:2181/mesos`) and Marathon
(`zk://127.0.0.1:2181/marathon`).

## Usage

```sh
./libscript.sh ls-remote zookeeper
./libscript.sh install zookeeper 3.9.2
./libscript.sh use zookeeper 3.9.2
./libscript.sh start zookeeper
./libscript.sh status zookeeper
./libscript.sh test zookeeper
./libscript.sh stop zookeeper
./libscript.sh uninstall zookeeper 3.9.2
```

```cmd
libscript.cmd install zookeeper 3.9.2
libscript.cmd start zookeeper
libscript.cmd status zookeeper
libscript.cmd test zookeeper
```

## Configuration

| Variable                   | Description                                                | Default                        |
| :------------------------- | :--------------------------------------------------------- | :----------------------------- |
| `ZOOKEEPER_VERSION`        | Specific version of Apache ZooKeeper to install.           | `3.9.2`                        |
| `ZOOKEEPER_INSTALL_METHOD` | How to install ZooKeeper (`libscript_native` or `system`). | `libscript_native`             |
| `ZOOKEEPER_CLIENT_PORT`    | Client TCP port.                                           | `2181`                         |
| `ZOOKEEPER_DATA_DIR`       | Directory for transaction logs and znode snapshots.        | `/var/lib/zookeeper`           |
| `ZOOKEEPER_SERVERS`        | Ensemble quorum server list.                               | `server.1=127.0.0.1:2888:3888` |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                          | Default                        | Aliases/Examples |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ---------------- |
| `ZOOKEEPER_VERSION`        | Specific version of Apache ZooKeeper to install.                                                                     | `3.9.2`                        | latest, stable   |
| `ZOOKEEPER_INSTALL_METHOD` | How to install Apache ZooKeeper ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages). | `libscript_native`             |                  |
| `ZOOKEEPER_CLIENT_PORT`    | TCP port on which ZooKeeper listens for client connections.                                                          | `2181`                         |                  |
| `ZOOKEEPER_DATA_DIR`       | Filesystem directory path for ZooKeeper transaction logs and znode snapshots.                                        | `/var/lib/zookeeper`           |                  |
| `ZOOKEEPER_SERVERS`        | Comma-separated list of ensemble server quorum definitions (e.g. 'server.1=127.0.0.1:2888:3888').                    | `server.1=127.0.0.1:2888:3888` |                  |
| `ZOOKEEPER_HOME`           | Filesystem directory or path configuration for zookeeper (ZOOKEEPER_HOME).                                           | `none`                         |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
