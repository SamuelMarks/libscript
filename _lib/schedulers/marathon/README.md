# Marathon Framework (`_lib/schedulers/marathon`)

**Tier**: `T1` (`_lib/schedulers/marathon/`) | **Capabilities**: `userland-package`,
`service-daemon`

## Overview

Standalone Version Manager for the **Marathon** container and application orchestration framework on
Apache Mesos. Exposes the `/ping`, `/v2/info`, `/v2/apps`, `/v2/pods`, `/v2/tasks`,
`/v2/deployments`, and `/v2/Queue` state endpoints and manages long-running services on Mesos.

## Usage

```sh
./libscript.sh ls-remote marathon
./libscript.sh install marathon 1.11.28
./libscript.sh use marathon 1.11.28
./libscript.sh start marathon
./libscript.sh status marathon
./libscript.sh test marathon
./libscript.sh stop marathon
./libscript.sh uninstall marathon 1.11.28
```

```cmd
libscript.cmd install marathon 1.11.28
libscript.cmd start marathon
libscript.cmd status marathon
libscript.cmd test marathon
```

## Configuration

| Variable                  | Description                                               | Default                        |
| :------------------------ | :-------------------------------------------------------- | :----------------------------- |
| `MARATHON_VERSION`        | Specific version of Marathon to install.                  | `1.11.28`                      |
| `MARATHON_INSTALL_METHOD` | How to install Marathon (`libscript_native` or `system`). | `libscript_native`             |
| `MARATHON_HTTP_PORT`      | Marathon v2 REST API HTTP port.                           | `8080`                         |
| `MARATHON_MASTER`         | Mesos Master or ZooKeeper master URL.                     | `zk://127.0.0.1:2181/mesos`    |
| `MARATHON_ZK`             | ZooKeeper URI for Marathon state persistence.             | `zk://127.0.0.1:2181/marathon` |
| `MARATHON_HOSTNAME`       | Advertised hostname or IP address.                        | `127.0.0.1`                    |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                  | Description                                                                                                         | Default                        | Aliases/Examples |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ---------------- |
| `MARATHON_VERSION`        | Specific version of Marathon to install.                                                                            | `1.11.28`                      | latest, stable   |
| `MARATHON_INSTALL_METHOD` | How to install Marathon ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages).        | `libscript_native`             |                  |
| `MARATHON_HTTP_PORT`      | TCP port on which the Marathon v2 REST API and UI listen.                                                           | `8080`                         |                  |
| `MARATHON_MASTER`         | Apache Mesos master connection URL or ZooKeeper master path (e.g. 'zk://127.0.0.1:2181/mesos' or '127.0.0.1:5050'). | `zk://127.0.0.1:2181/mesos`    |                  |
| `MARATHON_ZK`             | ZooKeeper connection URI for Marathon framework state persistence and HA leader election.                           | `zk://127.0.0.1:2181/marathon` |                  |
| `MARATHON_HOSTNAME`       | Advertised hostname or IP address for the Marathon scheduler node.                                                  | `127.0.0.1`                    |                  |
| `MARATHON_HOME`           | Filesystem directory or path configuration for marathon (MARATHON_HOME).                                            | `none`                         |                  |
| `MARATHON_STATE_DIR`      | Filesystem directory or path configuration for marathon (MARATHON_STATE_DIR).                                       | `none`                         |                  |
| `MARATHON_URL`            | HTTP base URL of the Marathon scheduler API endpoint (e.g., http://127.0.0.1:8080).                                 | `none`                         |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
