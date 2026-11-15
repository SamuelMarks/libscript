# QEMU Component

Installs and configures QEMU, KVM hardware acceleration, libvirt virtualization daemon, swtpm TPM
emulator, and OVMF / edk2 UEFI firmware files.

## Usage

```sh
# Install QEMU and KVM virtualization stack
./libscript.sh install qemu

# Test QEMU availability
./libscript.sh test qemu
```

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                   | Description                                                                                                       | Default                              | Aliases/Examples |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ---------------- |
| `QEMU_VERSION`             | Version of QEMU to install (default: latest)                                                                      | `latest`                             |                  |
| `QEMU_INSTALL_METHOD`      | Install method for QEMU (system, brew)                                                                            | `system`                             |                  |
| `QEMU_SETUP_KVM_GROUPS`    | Add current user to kvm and libvirt groups on Linux (1 or 0)                                                      | `1`                                  |                  |
| `QEMU_SETUP_UEFI_FIRMWARE` | Create standard edk2/OVMF UEFI firmware symlinks in /usr/local/share/qemu (1 or 0)                                | `1`                                  |                  |
| `QEMU_GPU_PASSTHROUGH`     | Configure generic bare-metal IOMMU and VFIO-PCI GPU passthrough setup for local development (1 or 0)              | `0`                                  |                  |
| `QEMU_VFIO_PCI_IDS`        | Comma-separated PCI vendor:device IDs (e.g. 10de:2684,10de:22ba) to bind to vfio-pci                              | ``                                   |                  |
| `QEMU_TARGET_ARCHS`        | Comma-separated QEMU system emulator target architectures verified/installed (arm,aarch64,riscv32,riscv64,x86_64) | `arm,aarch64,riscv32,riscv64,x86_64` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
