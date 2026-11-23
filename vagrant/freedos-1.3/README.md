# Vagrant Environment: FreeDOS 1.3 (`vagrant/freedos-1.3/`)

## Overview

Pre-configured Vagrant environment (`bento/freedos-1.3`) used for 32-bit DOS (`DOS32A` + OpenWatcom)
component PM and `COM1` serial `CTest` verification.

## Usage

```sh
cd vagrant/freedos-1.3
vagrant up
vagrant ssh
```

Run the automated serial `CTest` suite:

```sh
./vagrant/freedos-1.3/run_dos_ctest.sh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
