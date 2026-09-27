# macOS 14 ARM64 Test Environment

## Overview

Vagrant test harness using `bento/macos-14-arm64` on UTM / Apple Virtualization Framework for
validating macOS cross-platform compatibility on Apple Silicon (`aarch64`).

### Box Building

The `bento/macos-14-arm64` box is built using the custom Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Supported Host Platforms**: macOS Apple Silicon (`aarch64`).
- See [VAGRANT.md](../../VAGRANT.md) for detailed build and setup instructions.

## Usage

Execute local tests for macOS 14 via:

```sh
./tests/run_local_tests.sh <component> --os macos-14-arm64
```

Or run the automated sequential test runner:

```sh
./tests/run_macos_tests.sh all
```
