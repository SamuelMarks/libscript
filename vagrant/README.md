# Multi-OS Bento Vagrant Test Environments (`vagrant/`)

## Overview

`vagrant/` contains pre-configured `Vagrantfile` environments used by `tests/` and `Plane B`
empirical suites (`experiments/`) to verify LibScript across Linux, BSD, illumos, macOS, Windows 11,
FreeDOS, and historic/32-bit MS-DOS guests—with native `aarch64` and `x86_64`
QEMU/UTM/libvirt/VirtualBox support via the custom Bento fork (`SamuelMarks/bento` @
`multi-os-qemu-aarch64`).

> **Note:** To install the Vagrant CLI tool itself via LibScript, use the atomic `T1` recipe
> `_lib/iac/vagrant` (`./libscript.sh install vagrant`). The subdirectories under `vagrant/` are VM
> guest environments rather than an installable package. See [`../VAGRANT.md`](../VAGRANT.md) for
> full box-building instructions.

## Guest Environments

- **Linux**: [`alpine-3.24/`](./alpine-3.24/README.md), [`debian-13/`](./debian-13/README.md),
  [`rockylinux-10.2/`](./rockylinux-10.2/README.md)
- **BSD & illumos**: [`freebsd-15.1/`](./freebsd-15.1/README.md), [`omnios/`](./omnios/README.md)
- **Windows & macOS**: [`windows-11/`](./windows-11/README.md),
  [`macos-14-arm64/`](./macos-14-arm64/README.md)
- **Kubernetes The Hard Way Clusters**: [`k8s-thw-alpine/`](./k8s-thw-alpine/README.md),
  [`k8s-thw-debian/`](./k8s-thw-debian/README.md)
- **MS-DOS & FreeDOS (`dos32` Verification)**: [`freedos-1.3/`](./freedos-1.3/README.md),
  [`freedos-1.4/`](./freedos-1.4/README.md), [`msdos-1.25/`](./msdos-1.25/README.md),
  [`msdos-2.0/`](./msdos-2.0/README.md), [`msdos-4.0/`](./msdos-4.0/README.md), and shared serial
  `CTest` harness [`_common/`](./_common/README.md).

## Usage

```sh
# Boot a specific guest environment
cd vagrant/debian-13 && vagrant up

# Provision multiple guest environments in parallel
./vagrant/up_multiple.sh alpine-3.24 debian-13 freebsd-15.1
```
