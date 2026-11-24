# Unified Kernel Image (`.efi` UKI) Format Driver (`synthesis/formats/uki.{sh,cmd}`)

## Overview

`synthesis/formats/uki.sh` and `synthesis/formats/uki.cmd` package a staged Linux kernel, initramfs,
`/etc/os-release`, and kernel command line into a single Secure Boot signed UEFI `PE32` / `PE32+`
Unified Kernel Image (`.efi`).

When `ukify` and `sbsign` (`sbsigntools`) are installed, they are invoked directly with
user-supplied or ephemeral RSA-2048 X.509 Secure Boot keys (`sbverify` verified). On cross-platform
hosts without `ukify` or `sbsign`, the zero-dependency C11 `uki_c_packer.c` bundler emits a
standards-compliant `PE32` / `PE32+` (`IMAGE_SUBSYSTEM_EFI_APPLICATION`) binary embedding `.osrel`,
`.cmdline`, `.linux`, and `.initrd` COFF sections plus a `WIN_CERTIFICATE` Authenticode Data
Directory #4 signature table and companion `.efi.sig.json` receipt.

## Usage

```sh
# Synthesize a Secure Boot UKI .efi from the default Tiny Linux GCC profile
./libscript.sh package-as linux-kernel --format uki

# Synthesize a Clang-built UKI .efi for aarch64
./libscript.sh package-as linux-kernel --profile linux-kernel-clang-tiny --arch aarch64 --format uki
```

```cmd
.\libscript.cmd package-as linux-kernel --format uki --allow-stub
```
