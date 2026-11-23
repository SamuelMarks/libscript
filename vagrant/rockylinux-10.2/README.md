# Vagrant Environment: Rocky Linux 10.2 (`vagrant/rockylinux-10.2/`)

## Overview

Pre-configured Vagrant environment (`bento/rockylinux-10.2`) used for Enterprise Linux
(`dnf`/`.rpm`, SELinux, systemd) installer and stack verification.

## Usage

```sh
cd vagrant/rockylinux-10.2
vagrant up
vagrant ssh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
