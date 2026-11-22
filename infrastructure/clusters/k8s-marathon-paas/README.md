# Kubernetes + Marathon-Equivalent PaaS Topology (`infrastructure/clusters/k8s-marathon-paas`)

## Overview

Declarative T5 High-Availability cluster topology orchestrating **Kubernetes** (`kubernetes`,
`kubernetes-k0s`, `kubernetes-thw`), **k8s-marathon** (`infrastructure/clusters/k8s-marathon-paas`
PaaS application controller), and **netctl** (`_lib/networking/netctl`) ingress routing.

## Usage

```sh
./infrastructure/clusters/k8s-marathon-paas/cli.sh up
./infrastructure/clusters/k8s-marathon-paas/cli.sh status
./infrastructure/clusters/k8s-marathon-paas/cli.sh scale k8s-workers 5
./infrastructure/clusters/k8s-marathon-paas/cli.sh failover k8s-control-plane-0
./infrastructure/clusters/k8s-marathon-paas/cli.sh down
```

```cmd
infrastructure\clusters\k8s-marathon-paas\cli.cmd up
infrastructure\clusters\k8s-marathon-paas\cli.cmd status
infrastructure\clusters\k8s-marathon-paas\cli.cmd scale k8s-workers 5
infrastructure\clusters\k8s-marathon-paas\cli.cmd down
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
