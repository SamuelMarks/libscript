# Marathon Framework (`_lib/orchestration/marathon`)

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

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                        | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`             |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                         |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                      |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                         |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                         |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                         |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                       |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                            |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                         |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                         |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                         |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                         |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                         |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                         |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                            |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                            |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                         |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                         |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                         |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                         |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                         |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                         |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                         |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                         |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                         |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`                |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                         |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`          |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                         |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                         |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                            |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name`     |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                         |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                         |                  |
| `MARATHON_VERSION`                 | Specific version of Marathon to install.                                                                                                                                                                                                                                                                                        | `1.11.28`                      | latest, stable   |
| `MARATHON_INSTALL_METHOD`          | How to install Marathon ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages).                                                                                                                                                                                                                    | `libscript_native`             |                  |
| `MARATHON_HTTP_PORT`               | TCP port on which the Marathon v2 REST API and UI listen.                                                                                                                                                                                                                                                                       | `8080`                         |                  |
| `MARATHON_MASTER`                  | Apache Mesos master connection URL or ZooKeeper master path (e.g. 'zk://127.0.0.1:2181/mesos' or '127.0.0.1:5050').                                                                                                                                                                                                             | `zk://127.0.0.1:2181/mesos`    |                  |
| `MARATHON_ZK`                      | ZooKeeper connection URI for Marathon framework state persistence and HA leader election.                                                                                                                                                                                                                                       | `zk://127.0.0.1:2181/marathon` |                  |
| `MARATHON_HOSTNAME`                | Advertised hostname or IP address for the Marathon scheduler node.                                                                                                                                                                                                                                                              | `127.0.0.1`                    |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
