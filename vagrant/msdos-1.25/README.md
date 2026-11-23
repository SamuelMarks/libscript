# Vagrant Environment: Microsoft MS-DOS 1.25 (`vagrant/msdos-1.25/`)

## Overview

Pre-configured Vagrant environment (`bento/msdos-1.25`) used for historic MS-DOS compatibility
boundary and `COM1` serial harness testing.

## Usage

```sh
cd vagrant/msdos-1.25
vagrant up
vagrant ssh
```

Run the automated serial `CTest` suite:

```sh
./vagrant/msdos-1.25/run_dos_ctest.sh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
