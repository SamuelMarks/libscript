# Vagrant Environment: Debian 13 (Trixie) (`vagrant/debian-13/`)

## Overview

Pre-configured Vagrant environment (`bento/debian-13`) used for glibc, systemd, `.deb` packaging,
and multi-service stack verification.

## Usage

```sh
cd vagrant/debian-13
vagrant up
vagrant ssh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
