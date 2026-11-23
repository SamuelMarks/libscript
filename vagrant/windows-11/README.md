# Vagrant Environment: Windows 11 (`vagrant/windows-11/`)

## Overview

Pre-configured Vagrant environment (`bento/windows-11`) used for native `.cmd`/PowerShell parity,
Win32 PE helpers, WiX/`msi-rs` `.msi` installers, and GUI screenshot verification.

## Usage

```sh
cd vagrant/windows-11
vagrant up
vagrant ssh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
