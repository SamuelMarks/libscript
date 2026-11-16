# Open edX Multi-OS Vagrant, Installer & Guest-UI Experiment (`experiments/openedx`)

Declarative `installer-e2e` campaign verifying Open edX across clean Bento fork Vagrant VMs without
any app-specific orchestration code:

0. **Target OS & Vagrant Bento Fork**: Boots `--target-os=<os>` under `<bento_prefix>/<os>` across
   `virtualbox`, `libvirt`, `hyperv`, `vmware_desktop`, `qemu`, or `utm`, saving a clean `"vanilla"`
   snapshot.
1. **Target Package & Source**: Resolves `.msi`, `.exe`, `.deb`, `.rpm`, `.pkg`, or `.dmg` either
   from GitHub Releases (`--pkg-source=github-release`) or built anew on the host
   (`--pkg-source=build`).
2. **Isolated Install Modes**: Runs `headless`, `quick`, and `custom` installations individually,
   rolling back to the clean `"vanilla"` VM snapshot and asserting zero residual paths/ports before
   every mode.
3. **Desktop Icons Screenshot**: Captures `10b_desktop_icons.png` inside the guest when a GUI
   desktop is applicable (skipping cleanly on headless server guests).
4. **LMS Browser & Login**: Opens guest browser to LMS (`http://localhost:8000/login`), captures
   `11_browser_lms_focused.png`, logs in via guest CDP DOM automation, and captures
   `13_browser_lms_authenticated.png`.
5. **Studio CMS Browser & Login**: Opens guest browser to Studio CMS
   (`http://localhost:8001/signin`), captures `12_browser_studio_focused.png`, logs in via guest CDP
   DOM automation, and captures `14_browser_studio_authenticated.png`.

## Quickstart

```sh
# Dry-run resolved execution plan & ordered verification steps
./libscript.sh experiment run openedx --dry-run=1 --bento-prefix=bento --target-os=windows-11 --pkg-format=msi --pkg-source=github-release

# Full Windows 11 MSI campaign from GitHub Releases across headless, quick, and custom modes
./libscript.sh experiment run openedx --bento-prefix=bento --target-os=windows-11 --pkg-format=msi --pkg-source=github-release

# Build Debian .deb anew on host and run in Debian 13 Bento VM
./libscript.sh experiment run openedx --bento-prefix=bento --target-os=debian-13 --pkg-format=deb --pkg-source=build

# Run unit, matrix, idempotency, and WordPress/Odoo reusability smoke tests
./libscript.sh experiment test openedx
```

## Zero-Extension Reuse for WordPress, Odoo, and Other Stacks

Adding a full Vagrant + installer + desktop + browser login experiment for `wordpress`, `odoo`, or
any other stack in `_lib/` requires **zero changes** to `experiments/engine.{sh,cmd}` or
`_lib/_common/experiment/*`:

```sh
./libscript.sh experiment scaffold odoo --template=installer-e2e
./libscript.sh experiment scaffold wordpress --template=installer-e2e
```
