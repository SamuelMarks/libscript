# Debian 13 Test Environment

## Overview

Vagrant test harness using `bento/debian-13` for validating cross-platform compatibility on
QEMU/AArch64 systems (including macOS Apple Silicon) and x86_64 hosts.

### Box Building

The `bento/debian-13` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux,
  Windows, Intel macOS).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for Debian 13 via:

```sh
./tests/run_local_tests.sh <component> --os debian-13
```
