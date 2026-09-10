# Bento Builder Stack

Provisioning stack for Chef Bento box building on Linux, macOS, and cloud VMs (such as Azure nested virtualization VMs).

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

## Usage

```sh
# Provision the complete Bento builder stack
./libscript.sh install bento-builder

# Test and validate the environment
./libscript.sh test bento-builder
```
