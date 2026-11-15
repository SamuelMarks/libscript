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

| Variable                      | Description                                                                                                      | Default            | Aliases/Examples |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------ | ---------------- |
| `K8S_MARATHON_VERSION`        | Specific version of the k8s-marathon controller to install.                                                      | `1.0.0`            | latest, stable   |
| `K8S_MARATHON_INSTALL_METHOD` | How to install k8s-marathon ('libscript_native' isolates binaries in LIBSCRIPT_HOME, 'system' uses OS packages). | `libscript_native` |                  |
| `K8S_MARATHON_PORT`           | TCP port on which the k8s-marathon PaaS REST API listens.                                                        | `8081`             |                  |
| `K8S_MARATHON_NAMESPACE`      | Default Kubernetes namespace for reconciled Deployments, StatefulSets, Jobs, Services, and Ingresses.            | `default`          |                  |
| `K8S_MARATHON_KUBECONFIG`     | Filesystem path to the kubeconfig file used to communicate with the Kubernetes API server.                       | `~/.kube/config`   |                  |
| `K8S_MARATHON_BACKEND`        | Target Kubernetes distribution backend ('k8s', 'k0s', or 'k8s-thw').                                             | `k8s`              |                  |
| `K8S_MARATHON_HOME`           | Filesystem directory or path configuration for k8s-marathon (K8S_MARATHON_HOME).                                 | `none`             |                  |
| `K8S_MARATHON_STATE_DIR`      | Filesystem directory or path configuration for k8s-marathon (K8S_MARATHON_STATE_DIR).                            | `none`             |                  |
| `K8S_MARATHON_URL`            | Configuration variable K8S_MARATHON_URL for k8s-marathon.                                                        | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
