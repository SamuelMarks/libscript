# Shared Empirical & Installer-E2E Evaluation Harness (`experiments/_common/`)

Provides two complementary, zero-dependency substrates shared across all `experiments/<suite-id>/`
plugins:

1. **SIGPLAN Statistical Evaluation Substrate (`harness.{sh,cmd}`)**:
   `c_probes/libscript_bench_probe.c`, provenance verification (`RULE-1`), native ISA guards
   (`RULE-2`), cold/warm trial separation (`RULE-3`), C11 monotonic `ns` quantiles/IQR (`RULE-4`),
   and 5-OS RSS accounting (`RULE-5`).
2. **Generic Cross-OS Installer & Guest-UI Verification Substrate (`pkg_ui_runner.{sh,cmd}`)**:
   - `vagrant_substrate.{sh,cmd}` (`Step 0`): Configurable Bento fork box resolution
     (`--bento-prefix`, `--bento-dir`, `--target-os`), multi-provider Vagrant management
     (`virtualbox`, `libvirt`, `hyperv`, `vmware_desktop`, `qemu`, `utm`), and clean `"vanilla"` VM
     snapshot rollback/assertions.
   - `pkg_resolver.{sh,cmd}` (`Step 1`): Cross-OS `.msi`, `.exe`, `.deb`, `.rpm`, `.pkg`, and `.dmg`
     artifact resolution from GitHub Releases or host-side `libscript package_as` builders.
   - `install_modes.{sh,cmd}` (`Step 2`): Snapshot-isolated `headless`, `quick`, and `custom`
     installation workflows driven natively inside the guest OS.
   - `guest_ui_verify.{sh,cmd}` & `guest_capture_agent.{sh,cmd,ps1}` (`Steps 3-5`): 100%
     guest-native desktop shortcut and browser CDP authentication screenshot verification driven
     declaratively by any stack's `packaging.json` (`openedx`, `wordpress`, `odoo`, etc.).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
