# Kubernetes + Marathon-Equivalent PaaS Topology (`topologies/k8s-marathon-paas`)

## Overview
Declarative Tier 3.5 High-Availability cluster topology orchestrating **Kubernetes**
(`kubernetes`, `kubernetes-k0s`, `kubernetes-thw`), **k8s-marathon**
(`_lib/orchestration/k8s-marathon` PaaS application controller), and **netctl**
(`_lib/networking/netctl`) ingress routing.

## Usage
```sh
./topologies/k8s-marathon-paas/cli.sh up
./topologies/k8s-marathon-paas/cli.sh status
./topologies/k8s-marathon-paas/cli.sh scale k8s-workers 5
./topologies/k8s-marathon-paas/cli.sh failover k8s-control-plane-0
./topologies/k8s-marathon-paas/cli.sh down
```

```cmd
topologies\k8s-marathon-paas\cli.cmd up
topologies\k8s-marathon-paas\cli.cmd status
topologies\k8s-marathon-paas\cli.cmd scale k8s-workers 5
topologies\k8s-marathon-paas\cli.cmd down
```
