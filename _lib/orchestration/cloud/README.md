# LibScript Cloud-Init and NoCloud Orchestration

This directory provides utilities for bootstrapping virtual machine instances in cloud and
hypervisor environments using cloud-init:

- `gen_nocloud_iso.sh` / `gen_nocloud_iso.cmd`: Generates an ISO filesystem image labeled `cidata`
  with `user-data`, `meta-data`, and network configuration to enable fully automated cloud-init
  provisioning across local hypervisors (QEMU, KVM, VirtualBox, Proxmox) and cloud platforms.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable               | Description                                                                                            | Default  | Aliases/Examples |
| ---------------------- | ------------------------------------------------------------------------------------------------------ | -------- | ---------------- |
| `CLOUD_VERSION`        | Specific version of cloud to install.                                                                  | `latest` |                  |
| `CLOUD_INSTALL_METHOD` | How to install CLOUD. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager. | `system` |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
