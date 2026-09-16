# SunOS OmniOS Test Environment

## Overview

Vagrant test harness using `bento/omnios` for validating LibScript SunOS / OmniOS CE / illumos
compatibility, IPS (`pkg`) package management, and SMF init system integration on macOS Apple
Silicon (AArch64) and x86_64 hosts.

### Box Building

The `bento/omnios` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux,
  Windows, Intel macOS).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for SunOS OmniOS via:

```sh
./tests/run_local_tests.sh <component> --os omnios
```
