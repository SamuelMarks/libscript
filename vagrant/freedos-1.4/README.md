# Vagrant Environment: FreeDOS 1.4 (`vagrant/freedos-1.4/`)

## Overview

Pre-configured Vagrant environment (`bento/freedos-1.4`) used for 32-bit DOS (`DOS32A` + OpenWatcom)
component PM and `COM1` serial `CTest` verification.

## Usage

```sh
cd vagrant/freedos-1.4
vagrant up
vagrant ssh
```

Run the automated serial `CTest` suite:

```sh
./vagrant/freedos-1.4/run_dos_ctest.sh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
