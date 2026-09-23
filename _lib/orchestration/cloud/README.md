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
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
