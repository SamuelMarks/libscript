# Shared Vagrant MS-DOS & FreeDOS Serial CTest Harness (`vagrant/_common/`)

## Overview

`vagrant/_common/` (`dos_ctest_common.{sh,cmd}`) provides shared QEMU `COM1` serial-console
automation, FAT disk staging, and `DOS32A.EXE` / OpenWatcom 32-bit DOS test execution helpers
sourced by
`vagrant/{freedos-1.3,freedos-1.4,msdos-1.25,msdos-2.0,msdos-4.0}/run_dos_ctest.{sh,cmd}`.
