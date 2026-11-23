# Vagrant Environment: Microsoft MS-DOS 4.0 (`vagrant/msdos-4.0/`)

## Overview

Pre-configured Vagrant environment (`bento/msdos-4.0`) used for FAT16 disk and `dos32` binary
compatibility verification over QEMU `COM1`.

## Usage

```sh
cd vagrant/msdos-4.0
vagrant up
vagrant ssh
```

Run the automated serial `CTest` suite:

```sh
./vagrant/msdos-4.0/run_dos_ctest.sh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
