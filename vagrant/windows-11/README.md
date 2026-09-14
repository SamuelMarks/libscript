# Windows 11 Test Environment

## Overview

Vagrant test harness using `bento/windows-11` for validating LibScript Windows compatibility (`.cmd`
/ PowerShell execution, Windows package management, services, and native environments) on
QEMU/AArch64 systems (including macOS Apple Silicon) and x86_64 hosts.

### Box Building

The `bento/windows-11` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux,
  Windows).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for Windows 11 via:

```sh
./tests/run_local_tests.sh <component> --os windows-11
```

Or run automated batches across all components:

```sh
./tests/run_all_batches.sh --os windows-11
```
