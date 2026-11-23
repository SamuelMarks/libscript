# Vagrant Environment: macOS 14 Sonoma (ARM64) (`vagrant/macos-14-arm64/`)

## Overview

Pre-configured Vagrant environment (`macos-14-arm64`) used for Apple Silicon `launchd`,
`.pkg`/`.dmg` installer, and Homebrew/native version-manager verification.

## Usage

```sh
cd vagrant/macos-14-arm64
vagrant up
vagrant ssh
```

See [`../../VAGRANT.md`](../../VAGRANT.md) for custom Bento (`multi-os-qemu-aarch64`) box building
and snapshot management instructions.
