# Alpine 3.24 Test Environment

## Overview

Vagrant test harness providing a clean Alpine Linux 3.24 environment (`bento/alpine-3.24`) for
LibScript POSIX and package manager testing across macOS Apple Silicon (AArch64) and x86_64 hosts.

### Box Building

The `bento/alpine-3.24` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux,
  Windows, Intel macOS).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for Alpine 3.24 via:

```sh
./tests/run_local_tests.sh <component> --os alpine-3.24
```
