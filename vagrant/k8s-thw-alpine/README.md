# Vagrant Environment: Kubernetes The Hard Way (Alpine) (`vagrant/k8s-thw-alpine/`)

## Overview

Pre-configured Vagrant environment (`bento/alpine-3.24`) used for multi-node jumpbox, control-plane,
and worker topology testing for `infrastructure/clusters/kubernetes-thw/` on Alpine Linux.

## Usage

```sh
cd vagrant/k8s-thw-alpine
vagrant up
vagrant ssh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
