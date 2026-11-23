# Vagrant Environment: Microsoft MS-DOS 2.0 (`vagrant/msdos-2.0/`)

## Overview

Pre-configured Vagrant environment (`bento/msdos-2.0`) used for hierarchical directory MS-DOS
boundary and `COM1` serial harness testing.

## Usage

```sh
cd vagrant/msdos-2.0
vagrant up
vagrant ssh
```

Run the automated serial `CTest` suite:

```sh
./vagrant/msdos-2.0/run_dos_ctest.sh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
