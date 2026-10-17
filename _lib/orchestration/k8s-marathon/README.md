# Kubernetes Marathon-Equivalent PaaS Controller (`_lib/orchestration/k8s-marathon`)

## Overview

Standalone Version Manager for the **Kubernetes Marathon-Equivalent PaaS Controller**
(`k8s-marathon`). Exposes a Marathon v2-compatible PaaS REST/CLI interface (`/v2/apps`, `/v2/tasks`,
`/v2/deployments`, `/v2/info`, `/ping`) and reconciles Application specs directly into Kubernetes
`Deployment`, `StatefulSet`, `Job`, `Service`, and `Ingress` resources across `kubernetes`,
`kubernetes-k0s`, and `kubernetes-thw`.

## Usage

```sh
./libscript.sh ls-remote k8s-marathon
./libscript.sh install k8s-marathon 1.0.0
./libscript.sh use k8s-marathon 1.0.0
./libscript.sh start k8s-marathon
./libscript.sh status k8s-marathon
./libscript.sh test k8s-marathon
./libscript.sh stop k8s-marathon
./libscript.sh uninstall k8s-marathon 1.0.0
```

```cmd
libscript.cmd install k8s-marathon 1.0.0
libscript.cmd start k8s-marathon
libscript.cmd status k8s-marathon
libscript.cmd test k8s-marathon
```

## Configuration

| Variable                      | Description                                                   | Default            |
| :---------------------------- | :------------------------------------------------------------ | :----------------- |
| `K8S_MARATHON_VERSION`        | Specific version of k8s-marathon to install.                  | `1.0.0`            |
| `K8S_MARATHON_INSTALL_METHOD` | How to install k8s-marathon (`libscript_native` or `system`). | `libscript_native` |
| `K8S_MARATHON_PORT`           | PaaS REST API TCP port.                                       | `8081`             |
| `K8S_MARATHON_NAMESPACE`      | Target Kubernetes namespace.                                  | `default`          |
| `K8S_MARATHON_KUBECONFIG`     | Path to kubeconfig file.                                      | `~/.kube/config`   |
| `K8S_MARATHON_BACKEND`        | Target Kubernetes backend (`k8s`, `k0s`, `k8s-thw`).          | `k8s`              |

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                                                                                                                                                                     | Default                    | Aliases/Examples |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- | ---------------- |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, 'system' via OS/selected package manager, or third-party version managers).                                                                                                                  | `libscript_native`         |                  |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan', 'pkgx'). When set, overrides auto-detection in detect_pkg_mgr. | `none`                     |                  |
| `LIBSCRIPT_BUILD_TOOLCHAIN`        | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain).                                                             | `default`                  |                  |
| `LIBSCRIPT_CUSTOM_CC_BIN`          | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                                                                              | `none`                     |                  |
| `LIBSCRIPT_BUILD_CFLAGS`           | Global extra CFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `LIBSCRIPT_BUILD_LDFLAGS`          | Global extra LDFLAGS passed to source builds across components.                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override for Windows (winget, choco, scoop, vcpkg).                                                                                                                                                                                                                                                      | `winget`                   |                  |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                                                                                            | `1`                        |                  |
| `LIBSCRIPT_LOG_FORMAT`             | Output format for logs (text, json).                                                                                                                                                                                                                                                                                            | `text`                     |                  |
| `LIBSCRIPT_LOG_FILE`               | File to write logs to (in addition to standard output).                                                                                                                                                                                                                                                                         | `none`                     |                  |
| `LIBSCRIPT_SERVICE_NAME`           | Overrides the default service name.                                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `DOWNLOAD_DIR`                     | Directory where downloads are stored.                                                                                                                                                                                                                                                                                           | `none`                     |                  |
| `FORMAT`                           | Output format (e.g., json, text).                                                                                                                                                                                                                                                                                               | `none`                     |                  |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached files are stored.                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating whether offline mode is active, prohibiting outgoing network calls.                                                                                                                                                                                                                                    | `0`                        |                  |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict offline flag (0 or 1) that immediately aborts execution if network calls are attempted.                                                                                                                                                                                                                                  | `0`                        |                  |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory for temporary download artifacts.                                                                                                                                                                                                                                                                             | `none`                     |                  |
| `LIBSCRIPT_LOG_DRIVER`             | Logging driver to use (e.g., fluentd).                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `LOGS_DIR`                         | Directory where logs should be stored.                                                                                                                                                                                                                                                                                          | `none`                     |                  |
| `VAULT_TOKEN`                      | Token for HashiCorp Vault authentication.                                                                                                                                                                                                                                                                                       | `none`                     |                  |
| `PREFIX`                           | Installation prefix.                                                                                                                                                                                                                                                                                                            | `none`                     |                  |
| `SERVE_FROM`                       | Base directory or context path for the service.                                                                                                                                                                                                                                                                                 | `none`                     |                  |
| `LIBSCRIPT_LOG_HOST`               | Host for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `LIBSCRIPT_VERSION`                | Specifies the version of the package to use.                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `LIBSCRIPT_LOG_PORT`               | Port for remote logging.                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `TPU_ZONE`                         | GCP Zone for TPU provisioning                                                                                                                                                                                                                                                                                                   | `us-central2-b`            |                  |
| `TPU_ACCELERATOR_TYPE`             | Type of TPU accelerator (e.g. v4-8)                                                                                                                                                                                                                                                                                             | `v4-8`                     |                  |
| `TPU_VERSION`                      | TPU VM OS version                                                                                                                                                                                                                                                                                                               | `tpu-ubuntu2204-base`      |                  |
| `GCP_PROJECT_ID`                   | GCP Project ID                                                                                                                                                                                                                                                                                                                  | `none`                     |                  |
| `XPK_CLUSTER_NAME`                 | Name for the XPK GKE cluster                                                                                                                                                                                                                                                                                                    | `none`                     |                  |
| `TPU_TENSOR_PARALLEL_SIZE`         | Tensor parallel size for TPU serving                                                                                                                                                                                                                                                                                            | `1`                        |                  |
| `MODEL_NAME`                       | HuggingFace model string to serve                                                                                                                                                                                                                                                                                               | `your-org/your-model-name` |                  |
| `WORKLOAD_NAME`                    | Name of the XPK workload                                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `JETSTREAM_IMAGE`                  | Docker image for JetStream TPU inference                                                                                                                                                                                                                                                                                        | `none`                     |                  |
| `K8S_MARATHON_VERSION`             | Specific version of the k8s-marathon controller to install.                                                                                                                                                                                                                                                                     | `1.0.0`                    | latest, stable   |
| `K8S_MARATHON_INSTALL_METHOD`      | How to install k8s-marathon ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages).                                                                                                                                                                                                                | `libscript_native`         |                  |
| `K8S_MARATHON_PORT`                | TCP port on which the k8s-marathon PaaS REST API listens.                                                                                                                                                                                                                                                                       | `8081`                     |                  |
| `K8S_MARATHON_NAMESPACE`           | Default Kubernetes namespace for reconciled Deployments, StatefulSets, Jobs, Services, and Ingresses.                                                                                                                                                                                                                           | `default`                  |                  |
| `K8S_MARATHON_KUBECONFIG`          | Filesystem path to the kubeconfig file used to communicate with the Kubernetes API server.                                                                                                                                                                                                                                      | `~/.kube/config`           |                  |
| `K8S_MARATHON_BACKEND`             | Target Kubernetes distribution backend ('k8s', 'k0s', or 'k8s-thw').                                                                                                                                                                                                                                                            | `k8s`                      |                  |

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
