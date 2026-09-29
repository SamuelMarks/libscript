# LibScript `msi-rs` Live-CD / Live-USB Operator Guide

Complete operational guide for deploying, configuring, and executing the universal live-CD and
live-USB bootable installer powered by `msi-rs` across Linux, FreeBSD, and illumos.

---

## 1. Overview & Capabilities

The LibScript Live Installer is a cross-platform live operating system image that boots directly on
bare-metal or virtual hardware. It encapsulates the full `msi-rs` suite (`msi-cli`, `msi-gui`, WiX
tools, and msitools replacements) to perform:

- Storage device discovery, hardware geometry inspection, and safe partitioning (GPT, MBR, VTOC).
- Root filesystem formatting and ZFS pool provisioning (`ext4`, `xfs`, `btrfs`, `ufs2`, `zfs`).
- Base operating system installation for Linux (Alpine, Debian, Rocky, LFS), FreeBSD, and illumos.
- Offline preloading of complex web applications and platforms (Open edX, WordPress).

---

## 2. Boot Modes & Console Parameters

The live bootloader provides automated mode selection through kernel command-line arguments:

### Kernel Boot Flags (Linux & illumos)

- `mode=headless`: Bypasses interactive wizards and triggers unattended preseeded installation.
- `mode=tui`: Boots into the multi-screen curses terminal user interface on `tty1`.
- `mode=gui`: Starts the fullscreen Wayland (`cage`) or X11 (`openbox`) graphical kiosk installer.
- `console=ttyS0,115200`: Directs real-time installer transaction logs to the first serial port.

### FreeBSD Loader Settings (`loader.conf`)

- `boot_serial="YES"`: Enables serial console redirection.
- `comconsole_speed="115200"`: Configures serial baud rate.
- `boot_multicons="YES"`: Mirrors installer output across both video display and serial ports.

---

## 3. Operational Interaction Modes

### Mode A: Headless Unattended Installation (`msiexec /qn`)

For automated mass provisioning or automated cloud/hypervisor initializations, invoke:

```sh
# Direct CLI invocation with MSI property injection
./_lib/package-managers/msi-rs/engine/headless.sh /i installer.msi /qn
    TARGET_DISK=/dev/nvme0n1
    OS_FLAVOR=debian
    WORKLOAD=openedx

# Or driven via declarative response file:
./_lib/package-managers/msi-rs/engine/headless.sh --config /etc/autoinstall.json
```

On Windows Command Prompt:

```cmd
call _lib\package-managers\msi-rs\engine\headless.cmd /i installer.msi /qn TARGET_DISK=0
```

### Mode B: Terminal User Interface (TUI) Mode

The TUI wizard provides high-contrast terminal navigation for server consoles and SSH sessions:

```sh
./_lib/package-managers/msi-rs/engine/tui.sh
```

Wizards steps:

1. **Welcome & Keymap**: Select keyboard layout (US, UK, European).
2. **Target Storage**: Inspect storage geometry and select destination disk.
3. **Distribution**: Pick Linux, FreeBSD, or illumos.
4. **Workloads**: Checkbox selection for Open edX, WordPress, or minimal base.
5. **Partition Review**: Confirmation screen before destructive write operations.
6. **Live Progress**: Real-time status feed and progress gauge.
7. **Complete**: Drop to shell or reboot into new system.

### Mode C: Fullscreen Kiosk Graphical Interface (`msi-gui`)

The graphical kiosk interface launches fullscreen on top of hardware GPU drivers (Intel, AMD,
NVIDIA, VirtIO) with software rasterization fallback (`llvmpipe`):

```sh
./_lib/package-managers/msi-rs/engine/gui.sh
```

---

## 4. Advanced Visual Partitioning in `msi-gui`

The `msi-gui` interface provides an interactive, visual partition canvas allowing users to inspect
and customize disk layout prior to installation:

### Interactive Visual Disk Map

- **Color-Coded Canvas**: Partitions are rendered as proportional horizontal blocks, color-coded by
  filesystem type (e.g. green for ext4/xfs, blue for ZFS/UFS, yellow for FAT32 ESP, purple for
  swap).
- **Drag-and-Drop Sizing**: Boundary handles can be clicked and dragged to expand or shrink
  partition capacities, with real-time sector and gigabyte readouts.
- **Unallocated Space**: Free regions display an instant "+ Add Partition" button.

### Partition Table Scheme (MBR vs. GPT vs. VTOC)

- **Toggle Control**: Switch between GUID Partition Table (GPT) and Master Boot Record (MBR) or
  illumos SMI VTOC.
- **Firmware Safety Guard**: Emits a prominent warning if MBR is selected on UEFI-only hardware
  without CSM.

### Partition Role & Classification

- **MBR Roles**: Designate partitions as `Primary` (maximum of 4) or `Extended` with nested
  `Logical` partitions.
- **GPT Type GUIDs**: Select partition types with automatic GUID aliasing:
  - EFI System Partition (`ef00` / `c12a7328-f81f-11d2-ba4b-00a0c93ec93b`)
  - Linux Filesystem Data (`8300` / `0fc63daf-8483-4772-8e79-3d69d8477de4`)
  - Linux Swap (`8200` / `0657fd6d-a4ab-43c4-84e5-0933c84b4f4f`)
  - FreeBSD ZFS (`51687cba-600f-11d6-a2e4-005054508801`)
  - illumos Root (`6a898cc3-06c0-11d2-8e3f-00c04fa30c33`)
  - BIOS Boot Partition (`ef02` / `21686148-6449-6e6f-744e-656564454649`)
- **Active / Bootable Flag**: Toggle active partition status via a single checkbox.

### Filesystems and "Format vs. Reuse" Action Selector

- **Filesystem Dropdown**: Select `ext4`, `xfs`, `btrfs`, `ufs2`, `zfs`, `fat32`, `ntfs`, `exfat`,
  or leave `unformatted`.
- **Format vs. Reuse Switch**:
  - `Format (Destructive)`: Formats the partition with the selected filesystem, erasing all existing
    contents.
  - `Reuse (Non-destructive)`: Keeps existing files intact (e.g. preserving `/home` or data volumes
    across re-installs).
- **Mount Point Assignment**: Quick-select presets (`/`, `/boot`, `/boot/efi`, `/home`, `/var`,
  `/tmp`, `/opt`, `swap`) or custom entry.

### Validation Engine & Safety Interlocks

- **Sector Alignment**: Automatically enforces 1MiB (2048 sector) boundary alignment.
- **Collision Detection**: Real-time validation flags partition overlaps and unassigned root (`/`)
  partitions in red.
- **Confirmation Preview**: A clear before-and-after table summarizes all actions, explicitly
  highlighting destructive formats in red before writing to disk.

---

## 5. Universal Multiboot Co-Installation (Linux + FreeBSD + illumos)

The installer partitions storage devices and deploys any permutation of Linux, FreeBSD, and illumos
(triple-boot or dual-boot) with unified bootloader chaining:

### The `partitionary` Storage Engine

The installer abstracts disk partitioning via `partitionary` across all three target operating
systems:

- **MBR Partitioning**:
  - Allocates primary partition slots 1 to 4.
  - Toggles the active/bootable flag (`0x80` byte) on designated primary partitions for legacy BIOS
    boot routing.
  - Sets standard partition type IDs: Linux (`0x83`), Linux Swap (`0x82`), FreeBSD slice (`0xA5`),
    Solaris/illumos slice (`0xBF` or `0x82`).
  - Creates extended partition containers (`0x05`/`0x0F`) with Logical Drive EBR chains for 5+
    partitions.
  - Slices sub-partitions: FreeBSD `bsdlabel` (`da0s2a`, `da0s2b`, `da0s2d`) and illumos VTOC
    (`fmthard` slices 0..7).
- **GPT Partitioning**:
  - Enforces 1MiB sector alignment with Protective MBR (PMBR) or Hybrid MBR.
  - Configures standard GPT partition type GUIDs:
    - Shared EFI System Partition (ESP): `c12a7328-f81f-11d2-ba4b-00a0c93ec93b` (`ef00`)
    - BIOS Boot Partition: `21686148-6449-6e6f-744e-656564454649` (`ef02`)
    - Linux Filesystem Data: `0fc63daf-8483-4772-8e79-3d69d8477de4` (`8300`)
    - FreeBSD UFS/ZFS: `51687cb6-600f-11d6-a2e4-005054508801` /
      `51687cba-600f-11d6-a2e4-005054508801` (`a503`/`a504`)
    - illumos ZFS / Root: `6a898cc3-06c0-11d2-8e3f-00c04fa30c33` /
      `6a85724e-06c0-11d2-8e3f-00c04fa30c33` (`bf00`/`bf01`)

### Deployment via `SamuelMarks/msi-rs`

Multiboot provisioning is driven by pure Windows Installer (`.msi`) packages executed through the
`SamuelMarks/msi-rs` engine:

```sh
# Unattended Headless Triple-Boot Deployment
msi-cli /i multiboot_installer.msi /qn \
    TARGET_DISK=/dev/nvme0n1 \
    PARTITION_SCHEME=gpt \
    MULTIBOOT_LAYOUT="linux,freebsd,illumos" \
    BOOTLOADER_DEFAULT="debian" \
    BOOTLOADER_TIMEOUT=5
```

### Shared Bootloader & UEFI ESP Layout

In UEFI mode, a single shared 512MiB FAT32 ESP contains isolated bootloader trees:

- `/EFI/libscript/grubx64.efi`: Master GRUB2 bootloader menu.
- `/EFI/freebsd/loader.efi`: FreeBSD 15.1 native loader.
- `/EFI/illumos/bootx64.efi`: illumos / OmniOS native loader.

GRUB2 automatically synthesizes `grub.cfg` entries to boot Linux directly (kernel + initramfs),
chainload FreeBSD `loader.efi`, and chainload or directly multiboot illumos
(`multiboot2 /platform/i86pc/kernel/amd64/unix` with `/platform/i86pc/boot_archive`).

---

## 6. Dynamic Component Catalog & Clean Base

The live installer allows choosing between clean base installations and customized packages:

### Option A: Clean Base (Zero LibScript Workloads)

Install pure vanilla OS base without preloading any LibScript components:

```sh
./_lib/package-managers/msi-rs/engine/headless.sh WORKLOAD=none TARGET_DISK=/dev/sda
```

### Option B: Scrollable Dynamic Component Selection

Select any combination of components from the 260+ package catalog (e.g. `nginx`, `wordpress`,
`odoo`, `openedx`):

```sh
# Query dynamic catalog via CLI
./_lib/package-managers/msi-rs/preloader/catalog.sh --search web

# Install clean base with specific dynamic components
./_lib/package-managers/msi-rs/engine/headless.sh TARGET_DISK=/dev/sda \
    COMPONENTS="nginx,mariadb,wordpress,odoo"
```

---

## 7. Workload Preloading Guide

### Open edX Stack

Preloads LMS and Studio environments, MariaDB, MongoDB, Redis, and OpenSearch with pre-migrated
database schemas:

```sh
./_lib/package-managers/msi-rs/workloads/openedx.sh /mnt/target
```

### WordPress Stack

Preloads Nginx, PHP-FPM, MariaDB, and WordPress core with unique cryptographic salts:

```sh
./_lib/package-managers/msi-rs/workloads/wordpress.sh /mnt/target
```

---

## 8. Network Installation (PXE / Netboot)

To boot over the network using iPXE or PXE:

```ipxe
#!ipxe
kernel http://mirror.local/live/vmlinuz boot=live mode=headless TARGET_DISK=/dev/sda OS_FLAVOR=alpine
initrd http://mirror.local/live/initrd.img
boot
```

---

## 9. Multi-Platform Verification

All testing must be performed within Vagrant environments:

```sh
# Run full verification matrix across all 5 platforms
./tests/test_live_installer_matrix.sh --all

# Or on Windows:
call tests\test_live_installer_matrix.cmd --all
```

---

## 10. Harvested Screenshots & Verification Gallery

Automated screenshots captured during firmware boot, installation, bootloader selection, login, and
logged-in verification are archived into `../cc0-assets` and available on GitHub:

### Step 00: Firmware Boot

- `00_bios_firmware_boot_menu.png`: Aptio / UEFI BIOS setup utility showing boot order with live USB
  highlighted.

  [![00_bios_firmware_boot_menu](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/00_bios_firmware_boot_menu.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/00_bios_firmware_boot_menu.png)

### Steps 01 to 13: Windows Installer (`.msi`) Graphical Wizard (`msi-gui`)

- `01_msi_installer_welcome.png`: Initial installer popup with welcome text and disk selection card.

  [![01_msi_installer_welcome](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/01_msi_installer_welcome.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/01_msi_installer_welcome.png)

- `02_msi_partitioning_editor.png`: Visual partition editor with drag-and-drop boundary handles.

  [![02_msi_partitioning_editor](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/02_msi_partitioning_editor.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/02_msi_partitioning_editor.png)

- `03_msi_partition_disk_map.png`: Proportional color-coded disk map with LBA sector ranges.

  [![03_msi_partition_disk_map](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/03_msi_partition_disk_map.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/03_msi_partition_disk_map.png)

- `04_msi_mbr_gpt_scheme_toggle.png`: Partition scheme selector (GPT vs MBR) and active boot flag
  assignment.

  [![04_msi_mbr_gpt_scheme_toggle](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/04_msi_mbr_gpt_scheme_toggle.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/04_msi_mbr_gpt_scheme_toggle.png)

- `05_msi_partition_type_editor.png`: Primary/logical role and GPT Type GUID editor.

  [![05_msi_partition_type_editor](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/05_msi_partition_type_editor.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/05_msi_partition_type_editor.png)

- `06_msi_filesystem_format_reuse.png`: Filesystem selector and Format vs Reuse switch.

  [![06_msi_filesystem_format_reuse](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/06_msi_filesystem_format_reuse.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/06_msi_filesystem_format_reuse.png)

- `07_msi_partition_alignment_validation.png`: Alignment validation and collision interlock dialog.

  [![07_msi_partition_alignment_validation](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/07_msi_partition_alignment_validation.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/07_msi_partition_alignment_validation.png)

- `08_msi_os_selection.png`: Operating system distribution selector.

  [![08_msi_os_selection](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/08_msi_os_selection.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/08_msi_os_selection.png)

- `09_msi_multi_os_multiboot.png`: Visual multiboot co-installation and GRUB chainloading setup.

  [![09_msi_multi_os_multiboot](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/09_msi_multi_os_multiboot.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/09_msi_multi_os_multiboot.png)

- `10_msi_dynamic_component_catalog.png`: Dynamic package catalog scrollable table.

  [![10_msi_dynamic_component_catalog](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/10_msi_dynamic_component_catalog.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/10_msi_dynamic_component_catalog.png)

- `11_msi_workload_options.png`: Preloaded workload configuration pane.

  [![11_msi_workload_options](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/11_msi_workload_options.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/11_msi_workload_options.png)

- `12_msi_install_progress.png`: Fullscreen installation progress animation with log feed.

  [![12_msi_install_progress](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/12_msi_install_progress.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/12_msi_install_progress.png)

- `13_msi_complete_summary.png`: Post-installation completion dialog with reboot button.

  [![13_msi_complete_summary](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/13_msi_complete_summary.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/13_msi_complete_summary.png)

### Steps 14 to 18: Headless Streams & TUI Wizard

- `14_headless_partitioning_format.png`: Console terminal stream of partition creation and
  formatting.

  [![14_headless_partitioning_format](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/14_headless_partitioning_format.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/14_headless_partitioning_format.png)

- `15_headless_multiboot_deploy.png`: Console terminal stream of concurrent multi-OS extraction.

  [![15_headless_multiboot_deploy](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/15_headless_multiboot_deploy.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/15_headless_multiboot_deploy.png)

- `16_tui_wizard_disk_selector.png`: TUI curses disk device selector.

  [![16_tui_wizard_disk_selector](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/16_tui_wizard_disk_selector.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/16_tui_wizard_disk_selector.png)

- `17_tui_wizard_multiboot_confirm.png`: TUI partition scheme confirmation and warning prompt.

  [![17_tui_wizard_multiboot_confirm](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/17_tui_wizard_multiboot_confirm.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/17_tui_wizard_multiboot_confirm.png)

- `18_tui_scrollable_catalog.png`: Curses/ANSI paginated scrollable component catalog.

  [![18_tui_scrollable_catalog](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/18_tui_scrollable_catalog.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/18_tui_scrollable_catalog.png)

### Steps 19 to 22: Bootloader Screens

- `19_bootloader_grub_multiboot.png`: Master GRUB2 menu listing Linux, FreeBSD, and illumos.

  [![19_bootloader_grub_multiboot](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/19_bootloader_grub_multiboot.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/19_bootloader_grub_multiboot.png)

- `20_bootloader_freebsd_loader.png`: FreeBSD Beastie and Lua loader menu.

  [![20_bootloader_freebsd_loader](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/20_bootloader_freebsd_loader.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/20_bootloader_freebsd_loader.png)

- `21_bootloader_illumos_loader.png`: illumos / OmniOS bootloader with Boot Environments.

  [![21_bootloader_illumos_loader](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/21_bootloader_illumos_loader.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/21_bootloader_illumos_loader.png)

- `22_bootloader_systemd_boot.png`: Minimalist UEFI systemd-boot menu.

  [![22_bootloader_systemd_boot](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/22_bootloader_systemd_boot.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/22_bootloader_systemd_boot.png)

### Steps 23 to 28: Login Screens

- `23_login_linux_console.png`: Linux virtual console getty prompt (`debian-multiboot login:`).

  [![23_login_linux_console](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/23_login_linux_console.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/23_login_linux_console.png)

- `24_login_linux_display_manager.png`: Linux graphical greeter with session selector.

  [![24_login_linux_display_manager](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/24_login_linux_display_manager.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/24_login_linux_display_manager.png)

- `25_login_freebsd_console.png`: FreeBSD console login (`login:`).

  [![25_login_freebsd_console](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/25_login_freebsd_console.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/25_login_freebsd_console.png)

- `26_login_freebsd_display_manager.png`: FreeBSD graphical greeter.

  [![26_login_freebsd_display_manager](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/26_login_freebsd_display_manager.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/26_login_freebsd_display_manager.png)

- `27_login_illumos_console.png`: illumos console prompt (`omnios-multiboot console login:`).

  [![27_login_illumos_console](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/27_login_illumos_console.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/27_login_illumos_console.png)

- `28_login_illumos_display_manager.png`: illumos desktop greeter.

  [![28_login_illumos_display_manager](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/28_login_illumos_display_manager.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/28_login_illumos_display_manager.png)

### Steps 29 to 34: Logged-in System Inspection Screens

- `29_loggedin_linux_terminal.png`: Active Linux terminal running `uname -a` and
  `cat /etc/os-release`.

  [![29_loggedin_linux_terminal](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/29_loggedin_linux_terminal.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/29_loggedin_linux_terminal.png)

- `30_loggedin_linux_desktop_terminal.png`: Active Linux desktop environment with terminal running
  `uname -a` and `cat /etc/os-release`.

  [![30_loggedin_linux_desktop_terminal](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/30_loggedin_linux_desktop_terminal.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/30_loggedin_linux_desktop_terminal.png)

- `31_loggedin_freebsd_terminal.png`: Active FreeBSD terminal running `uname -a`,
  `cat /etc/os-release`, and `freebsd-version -kru`.

  [![31_loggedin_freebsd_terminal](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/31_loggedin_freebsd_terminal.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/31_loggedin_freebsd_terminal.png)

- `32_loggedin_freebsd_desktop_terminal.png`: Active FreeBSD desktop environment with terminal
  running system release commands.

  [![32_loggedin_freebsd_desktop_terminal](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/32_loggedin_freebsd_desktop_terminal.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/32_loggedin_freebsd_desktop_terminal.png)

- `33_loggedin_illumos_terminal.png`: Active illumos terminal running `uname -a`,
  `cat /etc/release`, and `zpool status -x`.

  [![33_loggedin_illumos_terminal](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/33_loggedin_illumos_terminal.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/33_loggedin_illumos_terminal.png)

- `34_loggedin_illumos_desktop_terminal.png`: Active illumos desktop environment with terminal
  running system release commands.

  [![34_loggedin_illumos_desktop_terminal](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/34_loggedin_illumos_desktop_terminal.png)](https://raw.githubusercontent.com/SamuelMarks/cc0-assets/master/libscript/live-installer/screenshots/34_loggedin_illumos_desktop_terminal.png)
