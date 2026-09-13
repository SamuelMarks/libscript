# Windows 11 Test Environment

## Overview

Vagrant test harness using `bento/windows-11` for validating LibScript Windows compatibility (`.cmd`
/ PowerShell execution, Windows package management, services, and native environments) on
QEMU/AArch64 systems.

## Usage

Execute local tests for Windows 11 via:

```sh
./tests/run_local_tests.sh <component> --os windows-11
```

Or run automated batches across all components:

```sh
./tests/run_all_batches.sh --os windows-11
```
