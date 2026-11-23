# Tier 4 (`T4`) High-Availability Cluster Substrates (`infrastructure/clusters/`)

## Overview

`infrastructure/clusters/` provisions and choreographs multi-node compute and container-orchestrator
cluster substrates governed by `cluster-substrate.schema.json` and backed by `T0`
`engine/consensus/{lock,fence}.{sh,cmd}`. Separating `T4` cluster substrates from `T5` application
constellations (`workloads/constellations/`) ensures workload schedulers and stateful services sit
strictly above cluster infrastructure without vertical DAG inversion.

## Cluster Blueprints

- [`gke-tpu-cluster/`](./gke-tpu-cluster/README.md): Google Kubernetes Engine (GKE) multi-slice
  Cloud TPU cluster substrate with XPK (`JobSet` + `Kueue`) and regional 4-role GCS buckets.
- [`k0s-ha/`](./k0s-ha/README.md): Zero-friction High-Availability Kubernetes (`k0s`) control-plane
  and worker cluster substrate.
- [`k8s-marathon-paas/`](./k8s-marathon-paas/README.md): Hybrid Kubernetes + Apache Mesos/Marathon
  co-scheduled PaaS cluster substrate.
- [`kubernetes-thw/`](./kubernetes-thw/README.md): Automated "Kubernetes The Hard Way" multi-node
  PKI, `etcd`, control-plane, `containerd`, and CNI cluster substrate across Debian and Alpine.
- [`mesos-marathon-ha/`](./mesos-marathon-ha/README.md): High-Availability ZooKeeper quorum, Apache
  Mesos Master/Agent, and Marathon cluster substrate.

## Usage

```sh
./libscript.sh cluster up infrastructure/clusters/k0s-ha/topology.json
./libscript.sh cluster status infrastructure/clusters/k0s-ha/topology.json
./libscript.sh cluster scale infrastructure/clusters/k0s-ha/topology.json workers=5
./libscript.sh cluster failover infrastructure/clusters/mesos-marathon-ha/topology.json master-2
./libscript.sh cluster destroy infrastructure/clusters/k0s-ha/topology.json
```

```cmd
.\libscript.cmd cluster up infrastructure\clusters\k0s-ha\topology.json
.\libscript.cmd cluster status infrastructure\clusters\k0s-ha\topology.json
```
