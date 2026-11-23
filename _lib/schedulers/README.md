# Cluster Orchestrators, Service Mesh & HPC Schedulers (`_lib/schedulers/`)

## Overview

**Tier Scope**: `T1`

Atomic cluster scheduler binaries and control-plane daemons (`kubernetes-k0s`, `k3s`, `kubeadm`,
`kubectl`, `nomad`, `mesos`, `marathon`, `slurm`, `consul`, `cilium`, `rancher`, `helm-controller`).

Each subdirectory in `_lib/schedulers/` is an atomic, self-contained LibScript component governed by
its own `manifest.json` and `vars.schema.json`. Components in `_lib/schedulers/` never cross-source
sibling components directly; instead, they source `T0` helpers from `engine/common/` and are
composed upward by `T3` (`synthesis/`), `T4` (`infrastructure/`), `T5` (`workloads/`), and `Plane A`
(`traits/`).

## Usage

Install or manage individual components in this category via `libscript.sh` / `libscript.cmd` or the
component's local `cli.sh` / `cli.cmd`:

```sh
./libscript.sh cilium --help
./libscript.sh install cilium latest
./_lib/schedulers/cilium/cli.sh test
```

```cmd
.\libscript.cmd cilium --help
.\libscript.cmd install cilium latest
.\_lib\schedulers\cilium\cli.cmd test
```

## Components (12)

<!-- BEGIN_COMPONENTS -->

- [`cilium`](./cilium/README.md) (`T1` — `userland-package`): Cilium CLI (cilium) for installing,
  managing, and troubleshooting eBPF-powered Kubernetes networking, observability, and security.
- [`consul`](./consul/README.md) (`T1` — `userland-package`, `service-daemon`): HashiCorp Consul
  service mesh, multi-datacenter service discovery, health checking, and distributed key-value
  store.
- [`helm-controller`](./helm-controller/README.md) (`T1` — `userland-package`): Kubernetes HelmChart
  custom resource operator (helm-controller) for declarative Helm release lifecycle management.
- [`k3s`](./k3s/README.md) (`T1` — `userland-package`, `service-daemon`): CNCF certified lightweight
  single-binary Kubernetes distribution (k3s) built for edge, IoT, CI, and cloud workloads.
- [`kubeadm`](./kubeadm/README.md) (`T1` — `userland-package`): Official Kubernetes cluster
  lifecycle bootstrapper (kubeadm init, kubeadm join, kubeadm upgrade).
- [`kubectl`](./kubectl/README.md) (`T1` — `userland-package`): Command-line client (kubectl) for
  communicating with a Kubernetes cluster control plane.
- [`kubernetes-k0s`](./kubernetes-k0s/README.md) (`T1` — `userland-package`, `service-daemon`): A
  zero-friction, all-in-one Kubernetes distribution.
- [`marathon`](./marathon/README.md) (`T1` — `userland-package`, `service-daemon`): Production-grade
  container and application orchestration framework for Apache Mesos.
- [`mesos`](./mesos/README.md) (`T1` — `userland-package`, `service-daemon`): Distributed systems
  kernel abstracting CPU, memory, storage, and compute resources across machines.
- [`nomad`](./nomad/README.md) (`T1` — `userland-package`, `service-daemon`): Flexible workload
  orchestrator to deploy and manage containers, microVMs, and non-containerized applications.
- [`rancher`](./rancher/README.md) (`T1` — `userland-package`, `service-daemon`): Rancher
  multi-cluster Kubernetes management CLI and control-plane server orchestration recipe.
- [`slurm`](./slurm/README.md) (`T1` — `userland-package`, `service-daemon`): Fault-tolerant, highly
  scalable cluster management and job scheduling system for HPC and AI training clusters.

<!-- END_COMPONENTS -->
