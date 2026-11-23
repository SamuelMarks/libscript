# Bento Builder Stack

Provisioning stack for Chef Bento box building on Linux, macOS, and cloud VMs (such as Azure nested
virtualization VMs).

## Stack Components

- **Hypervisors:**
  - QEMU / KVM with nested hardware acceleration and UEFI firmware symlinks
  - Oracle VirtualBox 7.0+ with Oracle Extension Pack (TPM 2.0 & Secure Boot)
  - Libvirt virtualization daemon and client tools
- **Image Builders & Runners:**
  - HashiCorp Packer
  - HashiCorp Vagrant (with `vagrant-libvirt` plugin)
- **Image & Windows Tools:**
  - `wimtools` (`wimlib-imagex`)
  - `xorriso`, `genisoimage`
  - `p7zip-full`, `cabextract`
  - `swtpm` (software TPM for QEMU)
- **Bento Environment:**
  - Ruby >= 3.1 runtime & Bundler
  - Automated `packer init` and `bundle install` inside local Bento repo

## Bento Repository

Building box images for **Windows** (Windows 11, Windows Server 2025), **Alpine**, latest
**FreeBSD**, and latest **Debian** across macOS Apple Silicon and x86_64 hosts requires the custom
Bento fork:

- **Repository**:
  [https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64](https://github.com/SamuelMarks/bento/tree/multi-os-qemu-aarch64)
  (`https://github.com/SamuelMarks/bento` @ branch `multi-os-qemu-aarch64`)
- **Host Architectures**: macOS Apple Silicon (`aarch64`) and other `x86_64` hosts (Linux, Windows,
  Intel macOS).

To clone this repository for the builder:

```sh
git clone -b multi-os-qemu-aarch64 https://github.com/SamuelMarks/bento.git
```

## Usage

```sh
# Provision the complete Bento builder stack
./libscript.sh install bento-builder

# Test and validate the environment
./libscript.sh test bento-builder
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                             | Description                                                                                                                                     | Default                                    |
| :----------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------- |
| `BENTO_DIR`                          | Path to the local bento repository (default: auto-detected from ../bento)                                                                       | `""`                                       |
| `BENTO_REPO_URL`                     | Git repository URL for the Bento fork (default: https://github.com/SamuelMarks/bento.git)                                                       | `https://github.com/SamuelMarks/bento.git` |
| `BENTO_BRANCH`                       | Git branch to checkout in the Bento repository (default: multi-os-qemu-aarch64)                                                                 | `multi-os-qemu-aarch64`                    |
| `BENTO_BUILDER_REPO_URL`             | Component-prefixed Git repository URL for the Bento fork (default: https://github.com/SamuelMarks/bento.git)                                    | `https://github.com/SamuelMarks/bento.git` |
| `BENTO_BUILDER_BRANCH`               | Component-prefixed Git branch to checkout in the Bento repository (default: multi-os-qemu-aarch64)                                              | `multi-os-qemu-aarch64`                    |
| `BENTO_BUILDER_INSTALL_MSDOS_PLUGIN` | Flag (1 or 0) to provision and verify Bento::VagrantMsdos and Bento::VagrantFreedos plugins for MS-DOS 1.25/2.0/4.0 and FreeDOS 1.3/1.4 guests. | `1`                                        |
| `BENTO_BUILDER_TARGET_OS`            | Target OS or DOS box identifier to build or register (e.g., msdos-1.25, msdos-2.0, msdos-4.0, freedos-1.3, freedos-1.4, debian-13).             | `""`                                       |
| `BENTO_BUILDER_FORCE_REBUILD`        | Flag (1 or 0) to force rebuilding Bento .box images even when build_complete artifacts already exist.                                           | `0`                                        |
| `INSTALL_QEMU`                       | Install QEMU/KVM virtualization (1 or 0)                                                                                                        | `1`                                        |
| `INSTALL_VIRTUALBOX`                 | Install VirtualBox 7.0 and Extension Pack (1 or 0)                                                                                              | `1`                                        |
| `INSTALL_PACKER`                     | Install HashiCorp Packer (1 or 0)                                                                                                               | `1`                                        |
| `INSTALL_VAGRANT`                    | Install HashiCorp Vagrant and plugins (1 or 0)                                                                                                  | `1`                                        |
| `INSTALL_IMAGE_TOOLS`                | Install ISO/WIM tools like wimtools, xorriso, 7zip (1 or 0)                                                                                     | `1`                                        |

> **Global Framework Variables**: Core paths, offline cache controls, and target triplet variables
> are documented in [`engine/common/README.md`](../../../engine/common/README.md).

<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
