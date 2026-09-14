# FreeBSD 15.1 Test Environment

## Overview

Vagrant test harness using `bento/freebsd-15.1` for validating LibScript FreeBSD `pkg` and BSD init
system compatibility on macOS Apple Silicon (AArch64) and x86_64 hosts.

### Box Building

The `bento/freebsd-15.1` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux,
  Windows, Intel macOS).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for FreeBSD 15.1 via:

```sh
./tests/run_local_tests.sh <component> --os freebsd-15.1
```
