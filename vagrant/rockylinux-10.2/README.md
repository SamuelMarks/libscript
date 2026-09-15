# Rocky Linux 10.2 Test Environment

## Overview

Vagrant test harness using `bento/rockylinux-10.2` for validating cross-platform compatibility and
RPM package management on QEMU/AArch64 systems (including macOS Apple Silicon) and x86_64 hosts.

### Box Building

The `bento/rockylinux-10.2` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux,
  Windows, Intel macOS).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for Rocky Linux 10.2 via:

```sh
./tests/run_local_tests.sh <component> --os rockylinux-10.2
```
