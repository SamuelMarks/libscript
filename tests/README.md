# Multi-OS Verification, Boot & Idempotency Test Suite (`tests/`)

## Overview

`tests/` contains LibScript's cross-platform verification harnesses spanning `T0`–`T5` and both
orthogonal planes (`traits/` and `experiments/`). See [`../TEST.md`](../TEST.md) for the complete
verification architecture.

## Test Suites

- **Idempotency & Standards Verification**:
  - `test_idempotency_matrix.{sh,cmd}`: Executes recipes twice consecutively and verifies zero
    unintended state mutation.
  - `test_win_dos_component_pm.{sh,cmd}`: Verifies native Windows PE and 32-bit MS-DOS (`dos32`)
    component package managers.
- **Synthesized OS, Unikernel & RTOS Headless Boot Harnesses**:
  - `os_boot_test.{sh,cmd}`, `freebsd_boot_test.{sh,cmd}`, `illumos_boot_test.{sh,cmd}`,
    `reactos_boot_test.{sh,cmd}`, `zephyr_boot_test.{sh,cmd}`, `freertos_boot_test.{sh,cmd}`, and
    [`boot_matrix/`](./boot_matrix/README.md).
  - `os_gui_smoke_test.{sh,cmd}`, `freebsd_gui_smoke_test.{sh,cmd}`,
    `illumos_gui_smoke_test.{sh,cmd}`, `reactos_gui_smoke_test.{sh,cmd}`: Headless `virtio-gpu`
    Wayland/X11/PipeWire desktop verification.
  - `test_airgap_boot.{sh,cmd}` & `test_live_installer_matrix.{sh,cmd}`: Strict
    `LIBSCRIPT_OFFLINE=1` air-gapped boot and `msi-rs` quad-OS live installer verification.
- **Container, Vagrant & Compatibility Aggregation**:
  - `run_alpine_tests.*`, `run_debian_tests.*`, `run_native_tests.*`, `run_local_tests.*`,
    `distro_pkg_roundtrip_test.*`, `cloud_image_test.*`, `container_smoke_test.*`.
  - `update_results.{sh,cmd,ps1}`: Aggregates test markers and updates the Supported Components
    compatibility table in [`../README.md`](../README.md).
