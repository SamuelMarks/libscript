# Vagrant Environment: Kubernetes The Hard Way (Debian) (`vagrant/k8s-thw-debian/`)

## Overview

Pre-configured Vagrant environment (`bento/debian-13`) used for multi-node jumpbox, control-plane,
and worker topology testing for `infrastructure/clusters/kubernetes-thw/` on Debian Linux.

## Usage

```sh
cd vagrant/k8s-thw-debian
vagrant up
vagrant ssh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
