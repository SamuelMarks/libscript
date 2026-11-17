# Vagrant Common DOS Helpers (`vagrant/_common`)

Shared POSIX `/bin/sh` (`dos_ctest_common.sh`) and Windows Batch (`dos_ctest_common.cmd`) harness
routines for booting, snapshotting (`vanilla`), synchronizing (`D:` `:freedos_sync` /
`:msdos_sync`), and executing 16-bit and 32-bit (`DOS32A.EXE` / `DOS4GW.EXE`) `CTest` workloads over
the `../bento` serial `COM1` communicators (`Bento::VagrantFreedos` and `Bento::VagrantMsdos`).
