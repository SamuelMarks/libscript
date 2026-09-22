# LibScript Universal OS, Distribution & Unikernel Synthesis: Exhaustive Engineering Plan

This document establishes the master engineering roadmap to transform **LibScript** into a universal
operating system, distribution, and unikernel synthesis framework. It merges the automated,
from-scratch compilation capabilities of **jhalfs** (LFS/BLFS) and Gentoo Catalyst with the
zero-dependency, decentralized shell architecture of LibScript.

In addition to building standard Glibc Linux distributions, this plan incorporates native
architectures for **musl-based Linux distributions** (Alpine/Void style), **FreeBSD (world, kernel,
ports, jails)**, **unikernels (Unikraft, OSv, MirageOS, Solo5)**, and **microVM guest images
(Firecracker, Cloud-Hypervisor)**.

---

## Core Engineering & Quality Invariants

Every subsystem, orchestrator, toolchain recipe, and packaging target in this plan must rigorously
adhere to LibScript's foundational standards:

1. **Strict POSIX `/bin/sh` Compliance:** All shell scripts must use `#!/bin/sh`. Banned: `bash`,
   `zsh`, `ksh`, and non-POSIX syntax (e.g., `[[`, `function`, non-POSIX parameter expansions, bash
   arrays). Every `.sh` script must feature the canonical `THIS_FILE=` path resolution and
   re-entrant `STACK` recursion guard within its first 65 lines.
2. **Universal Windows Batch Parity:** Every `.sh` script must have an exact functional Windows
   batch equivalent (`.cmd` or `.bat`) featuring delayed expansion, `set "THIS_FILE=%~f0"`, and the
   batch `STACK` recursion guard in its first 25 lines.
3. **End-to-End Idempotency & Re-entrancy:** Every script and recipe must be fully idempotent and
   re-runnable without unintended side-effects:
   - In shell: strictly use `mkdir -p` (never unguarded `mkdir`), `ln -sf` (never unguarded
     `ln -s`), atomic writes via temporary files, and mount checks (`mountpoint -q`, `findmnt`) with
     cleanup traps.
   - In batch: strictly wrap directory creations with `if not exist <dir> mkdir <dir>` and check
     file existence before writes.
   - Across pipelines: maintain stage stamp files (`.stageX_complete`, `.built`, `.installed`) so
     interrupted builds resume safely and duplicate executions result in clean no-ops.
4. **100% Documentation Coverage:** Standardized `## Overview` and `## Usage` doc blocks must appear
   in the first 30 lines of every `.sh`, `.cmd`, `.bat`, and `.ps1` script. Every JSON schema must
   provide 100% property description coverage. Every CLI command and variant must have complete
   reference documentation.
5. **Strict Remote Safety:** NEVER run `git push` in any script, automation routine, test harness,
   or CI pipeline.

---

## Master Checkbox Index

- [ ] [0. Framework Engineering Standards & Architectural Invariants](#0-framework-engineering-standards--architectural-invariants)
- [ ] [1. Declarative OS Configuration Specification (`os-config.schema.json`)](#1-declarative-os-configuration-specification-os-configschemajson)
- [ ] [2. Interactive Configurator & TUI Engine (`libscript config`)](#2-interactive-configurator--tui-engine-libscript-config)
- [ ] [3. Manifest & Solver Upgrades: USE Flags, Variants & Lifecycle Stages](#3-manifest--solver-upgrades-use-flags-variants--lifecycle-stages)
- [ ] [4. Sysroot, Target Rootfs & Filesystem Orchestration](#4-sysroot-target-rootfs--filesystem-orchestration)
- [ ] [5. Toolchain Bootstrapping & Multi-Stage Cross-Compilation](#5-toolchain-bootstrapping--multi-stage-cross-compilation)
- [ ] [6. Linux Base System Catalog Expansion: Glibc Ecosystem](#6-linux-base-system-catalog-expansion-glibc-ecosystem)
- [ ] [7. Linux Base System Catalog Expansion: Musl Ecosystem](#7-linux-base-system-catalog-expansion-musl-ecosystem)
- [ ] [8. Kernel, Initramfs & Firmware Subsystem](#8-kernel-initramfs--firmware-subsystem)
- [ ] [9. Init Systems & Service Managers](#9-init-systems--service-managers)
- [ ] [10. Graphics Stack & Display Hardware Acceleration](#10-graphics-stack--display-hardware-acceleration)
- [ ] [11. Display Protocols: Wayland and X11 Server Stacks](#11-display-protocols-wayland-and-x11-server-stacks)
- [ ] [12. Desktop Environments & Window Managers](#12-desktop-environments--window-managers)
- [ ] [13. Display Managers, Session Greeters & Desktop Portals](#13-display-managers-session-greeters--desktop-portals)
- [ ] [14. Audio & Multimedia Subsystems (PipeWire, PulseAudio, ALSA)](#14-audio--multimedia-subsystems-pipewire-pulseaudio-alsa)
- [ ] [15. Networking, Wireless & System Security Services](#15-networking-wireless--system-security-services)
- [ ] [16. Target Package Manager Integration (Porg, Pacman, Apk, Dpkg, Pkg, Xbps)](#16-target-package-manager-integration-porg-pacman-apk-dpkg-pkg-xbps)
- [ ] [17. FreeBSD Distribution Subsystem (World, Kernel, Jails, ZFS)](#17-freebsd-distribution-subsystem-world-kernel-jails-zfs)
- [ ] [18. Unikernel & MicroVM Subsystems (Unikraft, OSv, MirageOS, Firecracker)](#18-unikernel--microvm-subsystems-unikraft-osv-mirageos-firecracker)
- [ ] [19. Storage, Partitioning, Filesystems & Encryption](#19-storage-partitioning-filesystems--encryption)
- [ ] [20. Bootloaders, EFI Stubs & Unified Kernel Images (UKI)](#20-bootloaders-efi-stubs--unified-kernel-images-uki)
- [ ] [21. Bootable Output Formats (`package-as`)](#21-bootable-output-formats-package-as)
- [ ] [22. Automated Emulation, Headless Boot Verification & CI Matrix](#22-automated-emulation-headless-boot-verification--ci-matrix)

---

## 0. Framework Engineering Standards & Architectural Invariants

Establish mandatory LibScript engineering standards across all newly designed synthesis scripts,
subsystems, recipes, and automation tools.

- [ ] **0.1 Strict POSIX `/bin/sh` Compliance & Canonical `THIS_FILE=` Dance**
  - [ ] Enforce POSIX `/bin/sh` shebang (`#!/bin/sh`) on line 1 for every shell script; ban
        non-POSIX shells (bash, zsh, ksh) across all LibScript core utilities.
  - [ ] Implement canonical `THIS_FILE=` path resolution within the first 65 lines of all `.sh`
        scripts:
        `sh     set -feu     if [ "${SCRIPT_NAME-}" ]; then       THIS_FILE="${SCRIPT_NAME}"     elif [ "${BASH_SOURCE-}" ]; then       THIS_FILE="${BASH_SOURCE}"     else       THIS_FILE="${0}"     fi     `
  - [ ] Implement re-entrant `STACK` recursion guard in all `.sh` scripts to prevent infinite loops:
        `sh     case "${STACK+x}" in       *':'"${THIS_FILE}"':'*)         printf '[STOP]     processing "%s" ' "${THIS_FILE}" >&2         if (return 0 2>/dev/null); then return; else exit 0; fi ;;       *) printf '[CONTINUE] processing "%s" ' "${THIS_FILE}" >&2 ;;     esac     export STACK="${STACK:-}${THIS_FILE}"':'     `
  - [ ] Resolve `SCRIPT_DIR` and `LIBSCRIPT_ROOT_DIR` portably without external dependencies:
        `sh     SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)     : "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s ' "$d")}"     `
  - [ ] Ban `eval` and `Invoke-Expression` across all scripts (enforced via audit rules).

- [ ] **0.2 Windows Batch (`.cmd` / `.bat`) Parity & Dual-Platform Architecture**
  - [ ] Require a paired `.cmd` (or `.bat`) equivalent for every single `.sh` script created.
  - [ ] Implement canonical Windows batch header with delayed expansion and `THIS_FILE` resolution
        within the first 25 lines:
        `cmd     @echo off     setlocal EnableDelayedExpansion     set "THIS_FILE=%~f0"     `
  - [ ] Implement Windows batch `STACK` recursion guard matching POSIX semantics:
        `cmd     SET "searchVal=;%THIS_FILE%;"     IF NOT DEFINED STACK (         SET "STACK=;%THIS_FILE%;"         echo [CONTINUE] processing "%THIS_FILE%"     ) ELSE (         IF NOT "!STACK:%searchVal%=!"=="!STACK!" (             echo [STOP]     processing "%THIS_FILE%"             SET ERRORLEVEL=0             goto end         ) ELSE (             SET "STACK=!STACK!%THIS_FILE%;"             echo [CONTINUE] processing "%THIS_FILE%"         )     )     `
  - [ ] Ensure all CLI subcommands, orchestration helpers, VFS scripts, and image packagers execute
        natively on both POSIX and Windows hosts.

- [ ] **0.3 Universal Idempotency & Re-entrancy Guarantees**
  - [ ] POSIX shell filesystem idempotency:
    - [ ] Ban unguarded `mkdir`; strictly require `mkdir -p`.
    - [ ] Ban unguarded `ln -s`; strictly require `ln -sf`.
    - [ ] Use atomic file writes via temporary files and atomic moves (`mv -f`).
  - [ ] Windows batch filesystem idempotency:
    - [ ] Ban unguarded `mkdir` / `md`; strictly wrap directory creations with
          `if not exist "<dir>" mkdir "<dir>"`.
    - [ ] Verify file existence before copy/write operations to prevent overwrite prompts and
          failure states.
  - [ ] Execution state idempotency:
    - [ ] Maintain state stamps and verification markers (`.built`, `.installed`, `.configured`)
          allowing synthesis pipelines to resume seamlessly after interruptions.
    - [ ] Check mount points (`mountpoint -q`, `findmnt`) prior to mounting to prevent redundant
          mounts; register cleanup traps (`trap '...' EXIT INT TERM`) to avoid dangling VFS mounts.
    - [ ] Ensure all scripts pass 2x consecutive execution without error or mutated diffs.

- [ ] **0.4 100% Documentation Coverage & Audit Enforcement**
  - [ ] Mandate standardized documentation headers in the first 30 lines of every `.sh`, `.cmd`,
        `.bat`, and `.ps1` script: - [ ] `## Overview`: Concise description of purpose and
        architectural role. - [ ] `## Usage`: Execution instructions and invocation examples.
  - [ ] Maintain 100% schema documentation coverage in all JSON schemas (`os-config.schema.json`,
        `vars.schema.json`, `manifest.schema.json`) with exhaustive descriptions on every property.
  - [ ] Document all subcommands, variants, and options in corresponding Markdown guides.
  - [ ] Integrate automated compliance validation via `devtools/audit/audit_standards.sh` and
        `devtools/audit/audit_standards.cmd`.

- [ ] **0.5 Security, Safety & Git Invariants**
  - [ ] Strictly enforce safety mandates: NEVER execute `git push` under any circumstances in
        automated build routines, test runners, or CI pipelines.
  - [ ] Enforce non-destructive defaults across all disk and filesystem partitioning operations.

---

## 1. Declarative OS Configuration Specification (`os-config.schema.json`)

Establish a strongly-typed schema to represent complete system state, providing the bridge between
human configuration choices and automated build recipes. Ensure 100% documentation coverage for
every property in `os-config.schema.json`.

- [ ] **1.1 Base System & Target Architecture Properties**
  - [ ] Define `schema_version` with comprehensive description (semantic versioning for
        configuration spec, e.g., `1.0.0`).
  - [ ] Define target CPU architecture enum with full documentation:
    - [ ] `x86_64` (AMD64 / Intel 64)
    - [ ] `x86` (i686 / 32-bit PC)
    - [ ] `aarch64` (ARM64 / ARMv8-A+)
    - [ ] `armv7l` (ARM 32-bit hard-float)
    - [ ] `riscv64` (RISC-V 64-bit GC)
    - [ ] `powerpc64le` (POWER8/9 little-endian)
  - [ ] Define target CPU sub-model / optimization tuning:
    - [ ] `march` string (e.g., `generic`, `x86-64-v2`, `x86-64-v3`, `znver3`, `cortex-a72`,
          `native`).
    - [ ] `mtune` string.
  - [ ] Define target OS family enum:
    - [ ] `linux-glibc` (Standard GNU/Linux)
    - [ ] `linux-musl` (Minimalist Musl-based Linux)
    - [ ] `freebsd` (FreeBSD base system)
    - [ ] `unikernel-unikraft` (Unikraft microkernel)
    - [ ] `unikernel-osv` (OSv VM runtime)
    - [ ] `unikernel-mirage` (MirageOS OCaml unikernel)
    - [ ] `microvm-minimal` (Stripped Firecracker/Cloud-Hypervisor appliance)
  - [ ] Define target C standard library enum: `glibc`, `musl`, `nolibc`, `bsd-libc`, `newlib`.
  - [ ] Define binary format / ABI: `elf-gnu`, `elf-musl`, `elf-musleabi`, `elf-freebsd`.

- [ ] **1.2 Identity, Localization & System Environment**
  - [ ] Define `hostname` (RFC 1123 compliant string, default `libscript-box`).
  - [ ] Define `timezone` (IANA timezone database identifier, e.g., `UTC`, `America/New_York`,
        `Europe/London`).
  - [ ] Define `locale` settings:
    - [ ] `LANG` string (default `en_US.UTF-8` or `C.UTF-8`).
    - [ ] `LC_ALL`, `LC_CTYPE`, `LC_COLLATE`, `LC_MESSAGES`, `LC_TIME` overrides.
    - [ ] `locales_to_generate` array of locale definitions (e.g.,
          `["en_US.UTF-8 UTF-8", "de_DE.UTF-8 UTF-8"]`).
  - [ ] Define `console_keymap` (e.g., `us`, `de`, `fr`, `uk`, `dvorak`).
  - [ ] Define `console_font` (e.g., `Lat2-Terminus16`, `default8x16`).
  - [ ] Define `default_shell` enum (`/bin/sh`, `/bin/ash`, `/bin/bash`, `/bin/zsh`, default
        `/bin/sh`).

- [ ] **1.3 User Accounts, Authentication & Security Model**
  - [ ] Root account configuration:
    - [ ] `root_password_hash` (SHA-512 crypt or yescrypt hash).
    - [ ] `root_locked` (boolean; if true, direct root login disabled).
    - [ ] `root_ssh_keys` array (public OpenSSH keys for `/root/.ssh/authorized_keys`).
  - [ ] User accounts array (`users`):
    - [ ] `username` string (POSIX compliant username).
    - [ ] `uid` integer (default >= 1000).
    - [ ] `gid` integer or primary group name.
    - [ ] `supplementary_groups` list (e.g., `wheel`, `audio`, `video`, `input`, `seat`, `storage`,
          `network`).
    - [ ] `shell` path.
    - [ ] `password_hash` string.
    - [ ] `ssh_authorized_keys` array of strings.
    - [ ] `sudo_rule` enum (`nopasswd`, `require_password`, `none`).
  - [ ] Security framework configuration:
    - [ ] `mac_framework` enum (`none`, `apparmor`, `selinux`, `capsicum`).
    - [ ] `selinux_mode` enum (`disabled`, `permissive`, `enforcing`).
    - [ ] Hardening flags: `enable_stack_protector_strong`, `enable_fortify_source`, `enable_pie`,
          `enable_relro_now`.

- [ ] **1.4 Kernel Configuration Specification**
  - [ ] Define kernel provider enum:
    - [ ] `linux-stable` (latest stable from kernel.org)
    - [ ] `linux-lts` (latest long-term support release)
    - [ ] `linux-hardened` (security-enhanced patchset)
    - [ ] `linux-rt` (real-time PREEMPT_RT patchset)
    - [ ] `freebsd-kernel` (FreeBSD GENERIC or custom)
    - [ ] `unikraft-core` (Unikraft embedded kernel)
  - [ ] Define kernel version string or git branch / commit tag.
  - [ ] Define kernel configuration method enum:
    - [ ] `defconfig` (standard architecture default)
    - [ ] `tinyconfig` (minimal bootable size)
    - [ ] `allmodconfig` (modular build)
    - [ ] `custom_file` (path to full `.config` or FreeBSD `KERNCONF`)
    - [ ] `fragments` (base config plus list of `.cfg` snippets)
  - [ ] Define `kernel_config_file` path.
  - [ ] Define `kernel_config_fragments` array (e.g.,
        `["kvm_guest.cfg", "wayland_drm.cfg", "pipewire_audio.cfg", "zfs.cfg"]`).
  - [ ] Define out-of-tree kernel modules array:
    - [ ] `zfs` (OpenZFS kernel module)
    - [ ] `nvidia` (NVIDIA proprietary graphics driver)
    - [ ] `wireguard` (for kernels < 5.6)
    - [ ] `vboxguest` (VirtualBox guest additions)
    - [ ] `drm-kmod` (FreeBSD KMS driver port)
  - [ ] Define kernel command line (`cmdline`) string (e.g.,
        `console=ttyS0,115200 console=tty0 root=UUID=... rw quiet splash loglevel=3`).

- [ ] **1.5 Init System & Service Manager Specification**
  - [ ] Define init system enum:
    - [ ] `systemd` (Full-featured modern Linux init)
    - [ ] `openrc` (Dependency-based portable init)
    - [ ] `sysvinit` (Classic UNIX runlevel init)
    - [ ] `runit` (Fast, minimalist process supervisor)
    - [ ] `s6` / `s6-rc` (Skarnet robust process supervision suite)
    - [ ] `bsd-init` (FreeBSD standard `/etc/rc` system)
    - [ ] `none` (Direct container / unikernel PID 1 entrypoint)
  - [ ] Define default runlevel / target: `multi-user`, `graphical`, `rescue`, `default`.
  - [ ] Define enabled system services list: `sshd`, `chronyd`, `udevd`, `dbus`, `networkmanager`,
        `pipewire`, `firewall`, `acpid`, `seatd`.
  - [ ] Define disabled system services list.
  - [ ] Define custom init scripts / units injection map.

- [ ] **1.6 Display Server & Graphics Specification**
  - [ ] Define display server protocol enum:
    - [ ] `wayland` (Pure modern Wayland environment)
    - [ ] `x11` (Traditional X.Org server environment)
    - [ ] `hybrid-xwayland` (Wayland primary with XWayland compatibility server)
    - [ ] `headless` (Server / CLI only)
    - [ ] `framebuffer-only` (Direct Linux fbdev / DRM KMS console)
  - [ ] Define graphics acceleration driver list:
    - [ ] `mesa-gallium` (Open-source Gallium drivers)
    - [ ] `intel-media-driver` (Intel VA-API hardware decoding)
    - [ ] `amdgpu` (AMD modern open-source stack)
    - [ ] `nouveau` (Open-source NVIDIA driver)
    - [ ] `nvidia-proprietary` (Official NVIDIA binary driver)
    - [ ] `virgl` (QEMU 3D accelerated virtual GPU)
    - [ ] `virtio-gpu` (Standard virtual GPU)
    - [ ] `modesetting` (Generic KMS fallback driver)
  - [ ] Define Vulkan enablement: boolean, with specific loader and validation layer selections.
  - [ ] Define VA-API / VDPAU hardware video acceleration enablement: boolean.

- [ ] **1.7 Desktop Environment & User Experience Specification**
  - [ ] Define desktop environment enum:
    - [ ] `none` (No graphical desktop)
    - [ ] `gnome` (GNOME 4x full desktop suite)
    - [ ] `kde-plasma-6` (KDE Plasma 6 desktop suite)
    - [ ] `xfce4` (XFCE 4.18+ lightweight desktop)
    - [ ] `lxqt` (Qt-based lightweight desktop)
    - [ ] `sway` (i3-compatible Wayland tiling compositor)
    - [ ] `hyprland` (Dynamic tiling Wayland compositor with animations)
    - [ ] `weston` (Wayland reference compositor)
    - [ ] `labwc` (Openbox-like Wayland window-stacking compositor)
    - [ ] `openbox` (Minimalist X11 window manager)
  - [ ] Define display / login manager enum:
    - [ ] `none` (Virtual console getty prompt)
    - [ ] `greetd` (Lightweight daemon supporting tuigreet and gtkgreet)
    - [ ] `sddm` (Simple Desktop Display Manager, QML based)
    - [ ] `gdm` (GNOME Display Manager)
    - [ ] `lightdm` (Lightweight Display Manager)
  - [ ] Define auto-login parameters: `enabled` boolean, `user` string.
  - [ ] Define default theme and artwork bundle:
    - [ ] `gtk_theme` (e.g., `Adwaita`, `Breeze`, `Arc-Dark`).
    - [ ] `icon_theme` (e.g., `Papirus`, `Breeze`, `Adwaita`).
    - [ ] `cursor_theme` (e.g., `Bibata-Modern-Classic`, `Breeze_Cursors`).
    - [ ] `font_family` (e.g., `Inter`, `Noto Sans`, `JetBrains Mono`).
    - [ ] `wallpaper_path` (custom background image).

- [ ] **1.8 Audio, Multimedia & Peripheral Specification**
  - [ ] Define audio subsystem enum:
    - [ ] `pipewire` (Modern multimedia graph router)
    - [ ] `pulseaudio` (Traditional sound daemon)
    - [ ] `alsa-only` (Direct kernel ALSA without sound server)
    - [ ] `sndio` (Lightweight BSD audio daemon)
    - [ ] `none` (No sound stack)
  - [ ] Define PipeWire compatibility wrappers:
    - [ ] `pipewire-pulse` (PulseAudio API drop-in replacement)
    - [ ] `pipewire-jack` (JACK professional audio drop-in replacement)
    - [ ] `pipewire-alsa` (ALSA PCM redirect plugin)
  - [ ] Define session manager: `wireplumber` or `pipewire-media-session`.
  - [ ] Define Bluetooth audio support: boolean, with codec libraries (`libfreeaptx`, `ldacBT`,
        `fdk-aac`).

- [ ] **1.9 Networking & Network Management Specification**
  - [ ] Define network manager enum:
    - [ ] `networkmanager` (Full-featured network manager with nmcli / nmtui)
    - [ ] `systemd-networkd` (Lightweight systemd native network daemon)
    - [ ] `iwd-standalone` (Intel Wi-Fi daemon with integrated DHCP client)
    - [ ] `dhcpcd` (Portable multi-platform DHCP client)
    - [ ] `bsd-netif` (FreeBSD `/etc/rc.d/netif`)
    - [ ] `none` (Static IP / manual network configuration)
  - [ ] Define wireless daemon enum: `none`, `iwd`, `wpa_supplicant`.
  - [ ] Define DNS resolution enum: `systemd-resolved`, `resolvconf`, `static-resolv.conf`.
  - [ ] Define firewall daemon enum: `nftables`, `iptables`, `pf` (FreeBSD), `ipfw` (FreeBSD),
        `none`.
  - [ ] Define SSH server enum: `openssh`, `dropbear`, `none`.

- [ ] **1.10 Storage, Partitioning & Bootloader Specification**
  - [ ] Define target virtual disk size in GiB (e.g., `20`).
  - [ ] Define partition table format: `gpt`, `mbr`, `bsd-slice`.
  - [ ] Define boot mode: `uefi`, `bios-legacy`, `hybrid-uefi-bios`.
  - [ ] Define bootloader enum: `grub2-efi`, `grub2-bios`, `systemd-boot`, `limine`, `syslinux`,
        `freebsd-bootcode`, `none-direct-kernel`.
  - [ ] Define Unified Kernel Image (UKI) generation: boolean.
  - [ ] Define partitions list:
    - [ ] `partition_index` integer.
    - [ ] `label` string (e.g., `ESP`, `ROOT`, `HOME`, `SWAP`).
    - [ ] `size_mib` integer or `"remaining"` string.
    - [ ] `type_guid` (GPT partition type GUID, e.g., `c12a7328-f81f-11d2-ba4b-00a0c93ec93b` for
          EFI).
    - [ ] `filesystem` enum: `vfat`, `ext4`, `btrfs`, `xfs`, `f2fs`, `zfs`, `ufs2`, `swap`, `none`.
    - [ ] `mountpoint` string: `/`, `/boot`, `/boot/efi`, `/home`, `/var`, `swap`, `none`.
    - [ ] `mount_options` string (e.g., `noatime,compress=zstd:3`).
    - [ ] `luks` object: `enabled` boolean, `version` (`luks1` / `luks2`), `cipher`, `pbkdf`
          (`argon2id`), `keyfile` or `passphrase`.

---

## 2. Interactive Configurator & TUI Engine (`libscript config`)

Provide a terminal-based configuration editor matching the user experience of kernel `menuconfig`
and `jhalfs`. Ensure pure POSIX `/bin/sh` implementation and a matching Windows batch equivalent.

- [ ] **2.1 Core Menu Engine Abstraction (`cli/commands/config/`)**
  - [ ] Implement POSIX script `cli/commands/config/tui_engine.sh`:
    - [ ] Enforce `#!/bin/sh` shebang, canonical `THIS_FILE=` dance, and `STACK` recursion guard.
    - [ ] Provide 100% doc coverage (`## Overview` and `## Usage` in first 30 lines).
    - [ ] Detect available interactive TUI backends: `whiptail`, `dialog`, fallback ANSI VT100
          interactive script using POSIX `stty` / `read` (no bashisms).
  - [ ] Implement Windows batch equivalent `cli/commands/config/tui_engine.cmd`:
    - [ ] Enforce `set "THIS_FILE=%~f0"` and batch `STACK` recursion guard.
    - [ ] Provide 100% doc coverage (`## Overview` and `## Usage` in first 30 lines).
    - [ ] Support Windows native console dialogs and PowerShell TUI fallback.
  - [ ] Implement UI widget wrappers:
    - [ ] `tui_radiolist` (mutually exclusive single choice, e.g., Wayland vs. X11 vs. Headless).
    - [ ] `tui_checklist` (multiple selection, e.g., package features, GPU drivers).
    - [ ] `tui_inputbox` (text input, e.g., hostname, username, timezone).
    - [ ] `tui_passwordbox` (masked password entry for user and root passwords).
    - [ ] `tui_filepicker` (filesystem browser for custom `.config` files or wallpapers).
    - [ ] `tui_textbox` (scrollable viewer for licenses, READMEs, and help texts).
    - [ ] `tui_gauge` (progress bar for long-running build phases).
  - [ ] Implement menu navigation stack (`push_menu`, `pop_menu`, `current_menu`) with seamless Esc
        / Cancel handling.
  - [ ] Implement dynamic conditional visibility:
    - [ ] Hide Wayland compositor selection when `display_server == x11`.
    - [ ] Hide X11 driver selection when `display_server == wayland`.
    - [ ] Hide systemd unit manager when `init_system != systemd`.
    - [ ] Hide Glibc locales when `libc == musl`.
  - [ ] Implement contextual help window (`<Help>` button or `?` key) pulling markdown descriptions
        directly from `os-config.schema.json`.

- [ ] **2.2 Configuration Flow Dialogs**
  - [ ] **Main Menu**:
    - [ ] `[1]` Target Platform & Architecture
    - [ ] `[2]` Kernel & Hardware Drivers
    - [ ] `[3]` Init System & Base Daemons
    - [ ] `[4]` Display Protocols & Graphics
    - [ ] `[5]` Desktop Environment & Shell
    - [ ] `[6]` Audio, Media & Networking
    - [ ] `[7]` Storage, Filesystems & Bootloader
    - [ ] `[8]` Users, Security & Localization
    - [ ] `[9]` Save & Load Configuration Profiles
    - [ ] `[10]` Validate & Build OS
  - [ ] **Architecture Sub-Menu**:
    - [ ] Select Architecture: `x86_64`, `aarch64`, `riscv64`, `i686`.
    - [ ] Select C Library: `glibc` vs. `musl` vs. `bsd-libc` vs. `nolibc`.
  - [ ] **Display & Desktop Sub-Menu**:
    - [ ] Radio: `Wayland Native`, `X11 Classic`, `Wayland + XWayland`, `Headless Server`.
    - [ ] Desktop selector: `GNOME`, `KDE Plasma 6`, `XFCE 4`, `LXQt`, `Sway`, `Hyprland`, `Weston`,
          `None`.
    - [ ] Display Manager: `greetd (tuigreet/gtkgreet)`, `SDDM`, `GDM`, `LightDM`,
          `Console Autologin`.
  - [ ] **Audio & Graphics Sub-Menu**:
    - [ ] Sound server: `PipeWire (+ WirePlumber)`, `PulseAudio`, `ALSA Only`, `None`.
    - [ ] GPU Drivers: `Mesa Gallium/Vulkan (Intel, AMD, Nouveau)`, `NVIDIA Proprietary`,
          `VirtIO GPU`.
  - [ ] **Storage & Partitioning Wizard**:
    - [ ] Pre-made quick templates:
      - [ ] "Modern UEFI + Ext4 Single Root"
      - [ ] "Modern UEFI + Btrfs Subvolumes (@, @home, @snapshots)"
      - [ ] "Modern UEFI + Full Disk Encryption (LUKS2 + Btrfs)"
      - [ ] "FreeBSD Standard ZFS on Root"
      - [ ] "Legacy BIOS + MBR Ext4"
    - [ ] Interactive custom partition editor table.

- [ ] **2.3 Preset Profiles & CLI Commands**
  - [ ] Implement CLI command `./libscript.sh config os` and `libscript.cmd config os` (launches
        interactive TUI).
  - [ ] Implement CLI command `./libscript.sh config os --profile=<profile_name>` and
        `libscript.cmd ...` (loads template into TUI).
  - [ ] Implement CLI command `./libscript.sh config os --export=<file.json>` and
        `libscript.cmd ...` (dumps validated configuration to JSON).
  - [ ] Implement CLI command `./libscript.sh config os --validate=<file.json>` and
        `libscript.cmd ...` (headless schema validation with jq).
  - [ ] Implement CLI command `./libscript.sh config os --diff=<file1.json> <file2.json>` and
        `libscript.cmd ...` (visual configuration diff).
  - [ ] Ship built-in profiles in `profiles/` with 100% schema documentation:
    - [ ] `profiles/linux-minimal-headless.json` (Musl or Glibc stripped server).
    - [ ] `profiles/linux-desktop-sway-wayland.json` (Wayland, Sway, PipeWire, seatd, greetd).
    - [ ] `profiles/linux-desktop-hyprland.json` (Wayland, Hyprland, PipeWire, SDDM).
    - [ ] `profiles/linux-desktop-kde-plasma.json` (Plasma 6, Wayland, SDDM, PipeWire).
    - [ ] `profiles/linux-desktop-gnome.json` (GNOME 4x, Wayland, GDM, systemd).
    - [ ] `profiles/linux-desktop-xfce-x11.json` (XFCE 4.18, X11, LightDM, PulseAudio/PipeWire).
    - [ ] `profiles/linux-musl-hardened.json` (Musl, hardened kernel, s6/runit, BusyBox).
    - [ ] `profiles/freebsd-server-standard.json` (FreeBSD 14.x, ZFS root, OpenSSH).
    - [ ] `profiles/freebsd-desktop-xfce.json` (FreeBSD, XFCE, drm-kmod, devd).
    - [ ] `profiles/unikraft-microvm.json` (Unikraft Nginx/Redis microkernel).
    - [ ] `profiles/firecracker-microvm.json` (Ultra-stripped Linux kernel + initramfs root).

---

## 3. Manifest & Solver Upgrades: USE Flags, Variants & Lifecycle Stages

Evolve `manifest.json` and `resolve_stack.jq` to support build variants, feature flags (similar to
Gentoo USE flags and BLFS conditional options), and multi-pass dependency resolution.

- [ ] **3.1 Manifest Schema Extensions (`_lib/_common/manifest.schema.json`)**
  - [ ] Ensure 100% documentation coverage for all schema properties.
  - [ ] **Feature Flags / Variants (`variants` map)**:
    - [ ] Define variant flag key (e.g., `wayland`, `x11`, `pipewire`, `alsa`, `pulseaudio`,
          `systemd`, `pam`, `introspection`, `static`, `lto`, `vulkan`, `opengl`).
    - [ ] Add `description` string explaining what the variant enables.
    - [ ] Add `default_enabled` boolean.
    - [ ] Add `requires_variants` map (e.g., variant `gtk4[wayland]` requires `mesa[wayland]`).
    - [ ] Add `conflicts_variants` list (e.g., `static` conflicts with `shared`).
    - [ ] Add `build_args` map:
      - [ ] `configure_args` array of `./configure` flags (e.g.,
            `["--enable-wayland", "--disable-x11"]`).
      - [ ] `meson_args` array of Meson options (e.g., `["-Dwayland=true", "-Dx11=false"]`).
      - [ ] `cmake_args` array of CMake definitions (e.g., `["-DENABLE_WAYLAND=ON"]`).
      - [ ] `cflags` / `cxxflags` / `ldflags` arrays.
    - [ ] Add `variant_dependencies`:
      - [ ] `requires` array of component names.
      - [ ] `recommends` array of component names.
  - [ ] **Dependency Classification (`dependencies` object)**:
    - [ ] `host_tools` array: Tools executed on the build machine (e.g., `bison`, `flex`, `perl`,
          `python3`, `meson`, `ninja`, `pkg-config`, `nasm`).
    - [ ] `build_deps` array: Headers and static/shared libraries required in the target sysroot
          during compilation.
    - [ ] `runtime_deps` array: Programs, daemons, and plugins required in the target rootfs at
          runtime.
  - [ ] **Dependency Tiering (`tier` / `level`)**:
    - [ ] `required`: Hard dependency; failure to resolve aborts build.
    - [ ] `recommended`: Automatically selected unless explicitly excluded or in minimal profile.
    - [ ] `optional`: Only compiled if explicitly turned on in configuration.
  - [ ] **Target OS / Platform Constraints**:
    - [ ] `compatible_kernels`: array of `["linux", "freebsd", "unikraft"]`.
    - [ ] `compatible_libcs`: array of `["glibc", "musl", "bsd-libc", "nolibc"]`.
    - [ ] `supports_cross_compile`: boolean.
    - [ ] `requires_root`: boolean.

- [ ] **3.2 Constraint Solver Enhancements (`_lib/orchestration/resolve_stack.jq`)**
  - [ ] Provide POSIX wrapper `_lib/orchestration/resolve_stack.sh` and Windows batch equivalent
        `_lib/orchestration/resolve_stack.cmd`:
    - [ ] Both implement the `THIS_FILE=` dance, `STACK` recursion guard, and `## Overview` /
          `## Usage` doc blocks.
    - [ ] Ensure idempotent execution (cached graph output, deterministic order).
  - [ ] Propagate global `os-config.json` choices to all components:
    - [ ] If `display_server == "wayland"` or `hybrid-xwayland`, enable `wayland` variant on Mesa,
          GTK3, GTK4, Qt5, Qt6, SDL2, FFmpeg, PipeWire, libva.
    - [ ] If `display_server == "x11"`, enable `x11` variant and disable `wayland` variant.
    - [ ] If `audio_subsystem == "pipewire"`, enable `pipewire` variant on multimedia consumers.
  - [ ] Implement 3-tier dependency graph traversal:
    - [ ] Level 1 (Strict Minimal): Traverse only `required` dependencies.
    - [ ] Level 2 (Standard Distribution): Traverse `required` + `recommended` dependencies.
    - [ ] Level 3 (Complete Feature Matrix): Traverse `required` + `recommended` + `optional`
          dependencies.
  - [ ] Circular Dependency Cycle Breaking:
    - [ ] Implement Tarjan's strongly connected components algorithm inside `resolve_stack.jq`.
    - [ ] Identify known bootstrap loops:
      - [ ] `freetype` <-> `harfbuzz`
      - [ ] `glib` <-> `gobject-introspection`
      - [ ] `libxml2` <-> `python3`
      - [ ] `curl` <-> `libssh2` <-> `openssl`
    - [ ] Break detected cycles by generating a staged execution plan:
      - [ ] Pass 1: Build Package A with bootstrap flags (e.g., `harfbuzz` without `freetype`).
      - [ ] Pass 2: Build Package B fully linked (e.g., `freetype` linked against bootstrap
            `harfbuzz`).
      - [ ] Pass 3: Rebuild Package A fully linked (e.g., `harfbuzz` linked against full
            `freetype`).
  - [ ] Virtual Capability & Alternative Resolution:
    - [ ] Resolve `virtual/libc` -> `glibc` or `musl` based on target configuration.
    - [ ] Resolve `virtual/init` -> `systemd`, `openrc`, `sysvinit`, or `runit`.
    - [ ] Resolve `virtual/display-manager` -> `greetd`, `sddm`, `gdm`, or `lightdm`.
    - [ ] Resolve `virtual/wayland-compositor` -> `sway`, `hyprland`, or `weston`.
    - [ ] Resolve `virtual/cron` -> `dcron`, `cronie`, or `fcron`.
    - [ ] Resolve `virtual/mta` -> `postfix`, `exim`, or `sendmail`.

---

## 4. Sysroot, Target Rootfs & Filesystem Orchestration

Isolate the build process so that target binaries and configurations are staged in an independent
root directory without host pollution. All orchestration scripts must be strictly idempotent,
implemented in pure POSIX `/bin/sh` and Windows batch, and feature 100% doc coverage.

- [ ] **4.1 Rootfs Staging Manager (`_lib/orchestration/`)**
  - [ ] Implement `_lib/orchestration/rootfs.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance, `STACK`
        guard) and `_lib/orchestration/rootfs.cmd` (Windows batch equivalent).
  - [ ] Both scripts include `## Overview` and `## Usage` in their first 30 lines.
  - [ ] Implement `--target-rootfs=<path>` global flag and environment variable
        `LIBSCRIPT_TARGET_ROOTFS`.
  - [ ] Implement FHS directory tree initialization (`create_fhs_layout.sh` and
        `create_fhs_layout.cmd`):
    - [ ] Strictly use `mkdir -p` (POSIX) and `if not exist ... mkdir` (batch) for idempotency.
    - [ ] Standard hierarchy:
      - [ ] `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`
      - [ ] `/lib`, `/lib64`, `/usr/lib`, `/usr/lib64`
      - [ ] `/etc`, `/etc/opt`, `/etc/skel`
      - [ ] `/var`, `/var/log`, `/var/run`, `/var/lock`, `/var/tmp`, `/var/cache`
      - [ ] `/usr`, `/usr/local`, `/usr/share`, `/usr/include`, `/usr/src`
      - [ ] `/dev`, `/proc`, `/sys`, `/run`
      - [ ] `/boot`, `/boot/efi`
      - [ ] `/home`, `/root`
      - [ ] `/mnt`, `/media`, `/opt`, `/srv`
      - [ ] `/tmp` (with `chmod 1777`)
    - [ ] Support merged `/usr` configuration (`/bin -> usr/bin`, `/sbin -> usr/sbin`,
          `/lib -> usr/lib`, `/lib64 -> usr/lib64`) using idempotent `ln -sf`.
    - [ ] Support split `/usr` configuration for legacy compatibility.
  - [ ] Implement default configuration skeleton population:
    - [ ] `/etc/passwd` with root and system users (`daemon`, `bin`, `nobody`).
    - [ ] `/etc/group` with standard groups (`root`, `wheel`, `audio`, `video`, `input`, `disk`,
          `kvm`).
    - [ ] `/etc/shadow` with locked root password or generated hash.
    - [ ] `/etc/hosts` and `/etc/resolv.conf` initial setup.
    - [ ] `/etc/nsswitch.conf` setup (files, dns, systemd).
    - [ ] `/etc/profile` and `/etc/sh.shrc` POSIX startup files.
  - [ ] Implement file ownership and permission sanitization:
    - [ ] Force all files to `0:0` (root:root) except specific setuid/setgid binaries (`sudo`, `su`,
          `passwd`).
    - [ ] Verify no host user UIDs/GIDs leak into the target rootfs.

- [ ] **4.2 Virtual Kernel Filesystems (VFS) Mount & Teardown Helpers (`_lib/orchestration/`)**
  - [ ] Implement `_lib/orchestration/vfs.sh` and `_lib/orchestration/vfs.cmd`:
    - [ ] POSIX `/bin/sh` and Windows batch parity.
    - [ ] Canonical `THIS_FILE=` preamble dance and `STACK` recursion guard.
    - [ ] 100% doc coverage (`## Overview` and `## Usage` in first 30 lines).
  - [ ] Implement `mount_target_vfs.sh` and `mount_target_vfs.cmd`:
    - [ ] Idempotent mount operations: check if already mounted (`mountpoint -q` or `findmnt`)
          before mounting to prevent redundant mount points.
    - [ ] Bind-mount or mount `devtmpfs` at `<rootfs>/dev`.
    - [ ] Mount `devpts` at `<rootfs>/dev/pts` (`gid=5,mode=620`).
    - [ ] Mount `tmpfs` at `<rootfs>/dev/shm` (`mode=1777`).
    - [ ] Mount `proc` at `<rootfs>/proc`.
    - [ ] Mount `sysfs` at `<rootfs>/sys`.
    - [ ] Mount `tmpfs` at `<rootfs>/run`.
    - [ ] Bind-mount host `/etc/resolv.conf` into `<rootfs>/etc/resolv.conf` for network access
          during build.
    - [ ] Support FreeBSD VFS: mount `devfs`, `fdescfs`, and `procfs`.
  - [ ] Implement `umount_target_vfs.sh` and `umount_target_vfs.cmd`:
    - [ ] Idempotent unmount operations: verify mount status before unmounting.
    - [ ] Recursive unmount in reverse order (`umount -R`).
    - [ ] Force kill lingering child processes inside chroot (`fuser -km <rootfs>`).
    - [ ] Trap handlers: register cleanup traps (`trap 'umount_target_vfs' EXIT INT TERM ERR`) to
          prevent mount leaks.

- [ ] **4.3 Isolation & Execution Runners (`_lib/orchestration/`)**
  - [ ] Implement `_lib/orchestration/runner.sh` and `_lib/orchestration/runner.cmd`:
    - [ ] Pure POSIX `/bin/sh` and Windows batch parity.
    - [ ] Canonical `THIS_FILE=` dance and `STACK` recursion guard.
    - [ ] 100% doc coverage (`## Overview` and `## Usage`).
  - [ ] **Linux Namespace Runner (`chroot_unshare`)**:
    - [ ] Execute commands using
          `unshare --mount --uts --ipc --pid --fork chroot <rootfs> <command>`.
    - [ ] Sanitize environment variables:
      - [ ] `export PATH=/bin:/usr/bin:/sbin:/usr/sbin`
      - [ ] `export LC_ALL=C`
      - [ ] `export LANG=C`
      - [ ] `export HOME=/root`
      - [ ] `export TERM=linux`
      - [ ] Unset all host `LIBSCRIPT_*`, `CARGO_*`, `NPM_*`, `LD_LIBRARY_PATH` variables.
  - [ ] **Rootless User Namespace Runner (`chroot_user_ns`)**:
    - [ ] Support non-root execution via `unshare -U -r --mount`.
    - [ ] Fake root UID mapping inside user namespace (`0 1000 1`).
  - [ ] **Foreign Architecture Emulation Runner (`chroot_qemu_binfmt`)**:
    - [ ] Install static QEMU binary (`qemu-aarch64-static`, `qemu-riscv64-static`) into
          `<rootfs>/usr/bin/` using idempotent copy.
    - [ ] Register host `binfmt_misc` rule.
    - [ ] Enable compiling ARM64/RISC-V images on x86_64 host machines.

---

## 5. Toolchain Bootstrapping & Multi-Stage Cross-Compilation

Implement a clean, reproducible, idempotent toolchain bootstrap sequence inspired by LFS (Chapters
5–8) and Gentoo Catalyst. All bootstrap driver scripts must be POSIX `/bin/sh` with Windows batch
parity, re-entrant stamp file guards, and 100% doc coverage.

- [ ] **5.1 Architecture Triplets & Host Independence**
  - [ ] Standardize cross-compilation triplets:
    - [ ] `x86_64-libscript-linux-gnu`
    - [ ] `x86_64-libscript-linux-musl`
    - [ ] `aarch64-libscript-linux-gnu`
    - [ ] `aarch64-libscript-linux-musl`
    - [ ] `riscv64-libscript-linux-gnu`
    - [ ] `riscv64-libscript-linux-musl`
    - [ ] `x86_64-unknown-freebsd14.0`
  - [ ] Enforce compiler flags for reproducibility:
    - [ ] `-fno-common`, `-fPIC`, `-fstack-protector-strong`, `-D_FORTIFY_SOURCE=2`.
    - [ ] Set `SOURCE_DATE_EPOCH` for reproducible builds across all compilation passes.

- [ ] **5.2 Stage 0: Host-Driven Cross-Toolchain Compilation (`/tools`)**
  - [ ] Implement Stage 0 driver script with POSIX `/bin/sh` (`stage0.sh`) and Windows batch
        (`stage0.cmd`):
    - [ ] Include canonical `THIS_FILE=` dance, `STACK` recursion guard, and `## Overview` /
          `## Usage`.
    - [ ] Idempotent check: verify `.stage0_complete` stamp before building.
  - [ ] Build isolated cross-Binutils Pass 1:
    - [ ] `--target=$TARGET_TRIPLET`, `--prefix=/tools`, `--with-sysroot=$SYSROOT`, `--disable-nls`,
          `--disable-werror`.
  - [ ] Build standalone cross-GCC Pass 1:
    - [ ] `--target=$TARGET_TRIPLET`, `--prefix=/tools`, `--without-headers`, `--with-newlib`,
          `--enable-languages=c`.
    - [ ] Inhibit `libgcc` thread support and shared library building.
  - [ ] Install Linux Kernel API headers:
    - [ ] `make headers_install INSTALL_HDR_PATH=/tools/$TARGET_TRIPLET`.
    - [ ] Clean headers (`find . -name '..install.cmd' -delete`).
  - [ ] Build Target C Standard Library:
    - [ ] For Glibc: compile `glibc` using cross-GCC Pass 1, install to `/tools/$TARGET_TRIPLET`.
    - [ ] For Musl: compile `musl` using cross-GCC Pass 1, install to `/tools/$TARGET_TRIPLET`.
  - [ ] Build cross-GCC Pass 2:
    - [ ] Build full C and C++ compiler with target libc support: `--enable-languages=c,c++`,
          `--disable-libstdcxx-pch`, `--with-sysroot=$SYSROOT`.

- [ ] **5.3 Stage 1: Cross-Compiled Minimal Userland (`/tools`)**
  - [ ] Implement Stage 1 driver script with POSIX `/bin/sh` (`stage1.sh`) and Windows batch
        (`stage1.cmd`):
    - [ ] Canonical `THIS_FILE=` dance, `STACK` guard, and `## Overview` / `## Usage`.
    - [ ] Idempotent check: verify `.stage1_complete` stamp.
  - [ ] Cross-compile foundational utilities into `/tools` linked against `/tools/lib/libc.so`:
    - [ ] `m4`, `ncurses`, `dash` / `sh` (POSIX `/bin/sh`), `coreutils`, `diffutils`, `file`,
          `findutils`, `gawk`, `grep`, `gzip`, `make`, `patch`, `sed`, `tar`, `xz`.
  - [ ] Linker sanitization verification:
    - [ ] Run `readelf -l <binary> | grep interpreter` on compiled binaries.
    - [ ] Assert interpreter matches `/tools/lib/ld-linux*.so` or `/tools/lib/ld-musl*.so` (zero
          reference to host `/lib64/ld-linux-x86-64.so.2`).

- [ ] **5.4 Stage 2: Final Self-Hosting Target Compilation (Inside Chroot)**
  - [ ] Implement Stage 2 driver script with POSIX `/bin/sh` (`stage2.sh`) and Windows batch
        (`stage2.cmd`):
    - [ ] Canonical `THIS_FILE=` dance, `STACK` guard, and `## Overview` / `## Usage`.
    - [ ] Idempotent check: verify `.stage2_complete` stamp.
  - [ ] Pivot into `<rootfs>` using `/tools` environment.
  - [ ] Native compilation sequence inside chroot:
    - [ ] `man-pages` (Linux manual pages)
    - [ ] Target C Library: `glibc` (with full locale compilation via `localedef`) or `musl`
    - [ ] `zlib`, `bzip2`, `xz`, `zstd` (compression libraries)
    - [ ] `file`, `readline`, `m4`, `bc`, `flex`, `bison`
    - [ ] `binutils` (final native assembler, linker `ld.bfd` / `ld.gold`)
    - [ ] `gmp`, `mpfr`, `mpc`, `isl` (math libraries)
    - [ ] `attr`, `acl`, `libcap`, `shadow`
    - [ ] `gcc` (final native GCC C/C++ compiler with LTO and OpenMP)
    - [ ] `pkg-config` / `pkgconf`
    - [ ] `ncurses`, `libtool`, `gdbm`, `gperf`, `expat`
    - [ ] `perl`, `XML::Parser`, `intltool`
    - [ ] `autoconf`, `automake`, `kmod`, `elfutils`, `libffi`
    - [ ] `python3`, `ninja`, `meson`
    - [ ] `coreutils`, `check`, `diffutils`, `gawk`, `findutils`, `groff`, `less`, `gzip`
    - [ ] `iproute2`, `kbd`, `libpipeline`, `make`, `patch`, `tar`, `texinfo`, `vim`
    - [ ] `eudev` / `systemd-udevd`, `util-linux`, `e2fsprogs`
  - [ ] Strip debug symbols from binaries (`strip --strip-unneeded`) to reduce size.
  - [ ] Delete `/tools` staging tree from rootfs.

---

## 6. Linux Base System Catalog Expansion: Glibc Ecosystem

Provide complete, granular recipes in `_lib/base-system/` for Glibc-based distributions. All recipes
must provide paired `setup.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance, `STACK` guard) and `setup.cmd`
(Windows batch equivalent), 100% doc coverage (`## Overview`, `## Usage`), and strictly idempotent
actions.

- [ ] **6.1 Glibc & Locales (`_lib/base-system/glibc/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance and `STACK` recursion
        guard.
  - [ ] Source acquisition and integrity check (Glibc release tarball + patches).
  - [ ] Compilation with optimized multi-arch flags.
  - [ ] Idempotent locales generation from `os-config.json`
        (`localedef -i <locale> -f <charmap> <dest>`).
  - [ ] Automated generation of `/etc/nsswitch.conf` and `/etc/ld.so.conf` /
        `/etc/ld.so.conf.d/*.conf` (check before append to preserve idempotency).
  - [ ] Execution of `ldconfig -r <target-rootfs>`.

- [ ] **6.2 Core POSIX System Utilities**
  - [ ] `coreutils`: Full GNU coreutils suite (`ls`, `cp`, `mv`, `cat`, `date`, `chmod`, `chown`,
        etc.).
  - [ ] `util-linux`: Essential disk and process tools (`fdisk`, `sfdisk`, `blkid`, `mount`,
        `umount`, `agetty`, `login`, `kill`, `dmesg`).
  - [ ] `e2fsprogs`: Ext2/Ext3/Ext4 filesystem utilities (`mkfs.ext4`, `fsck.ext4`, `tune2fs`,
        `resize2fs`).
  - [ ] `btrfs-progs`: Btrfs filesystem utilities (`mkfs.btrfs`, `btrfs subvolume create`,
        `btrfs scrub`).
  - [ ] `xfsprogs`: XFS filesystem utilities (`mkfs.xfs`, `xfs_repair`, `xfs_growfs`).
  - [ ] `dosfstools`: FAT/VFAT filesystem utilities (`mkfs.vfat`, `fsck.vfat`).

- [ ] **6.3 Device & Module Management**
  - [ ] `kmod`: Linux kernel module handling utilities (`modprobe`, `insmod`, `rmmod`, `lsmod`,
        `modinfo`, `depmod`).
  - [ ] `eudev`: Standalone dynamic `/dev` management daemon (for non-systemd systems).
  - [ ] `systemd-udevd`: Built-in udev daemon (for systemd systems).
  - [ ] Default udev rules setup (`60-persistent-storage.rules`, `80-net-setup-link.rules`).

- [ ] **6.4 Authentication & Permissions**
  - [ ] `shadow`: Password encryption, user creation (`useradd`, `usermod`, `userdel`, `groupadd`,
        `passwd`).
  - [ ] `pam` (Pluggable Authentication Modules):
    - [ ] Compilation of `libpam`, `pam_unix`, `pam_env`, `pam_limits`.
    - [ ] Idempotent templating of `/etc/pam.d/system-auth`, `/etc/pam.d/login`, `/etc/pam.d/sshd`,
          `/etc/pam.d/sudo`.
  - [ ] `sudo`: Privilege delegation with `/etc/sudoers` rules.
  - [ ] `doas`: Lightweight OpenBSD `doas` alternative for minimalist setups.

---

## 7. Linux Base System Catalog Expansion: Musl Ecosystem

Implement lightweight, memory-efficient recipes in `_lib/base-system/musl/` for Musl-based
distributions (Alpine / Void style). All recipes must provide paired `setup.sh` and `setup.cmd`,
canonical `THIS_FILE=` dance, idempotency, and 100% doc coverage.

- [ ] **7.1 Musl C Library Core (`_lib/base-system/musl/`)**
  - [ ] Provide `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch) with `THIS_FILE=` dance
        and `STACK` guard.
  - [ ] Compilation of `musl` with dynamic linker `/lib/ld-musl-x86_64.so.1`.
  - [ ] Musl UTF-8 C.UTF-8 default locale configuration.
  - [ ] Compatibility helper shims for GNU software:
    - [ ] `musl-fts` (implementation of `fts(3)` API).
    - [ ] `musl-obstack` (implementation of GNU `obstack` API).
    - [ ] `argp-standalone` (implementation of GNU `argp` argument parsing).
    - [ ] `libucontext` (ucontext implementation for coroutines/fibers).
    - [ ] `gettext-tiny` (lightweight `gettext` replacement).

- [ ] **7.2 Minimalist Userland Alternatives**
  - [ ] `busybox`:
    - [ ] Automated `.config` generator (multi-call binary providing `sh`, `coreutils`, `init`,
          `syslogd`, `mknod`).
    - [ ] Idempotent applet symlink generator (`busybox --install -s <target-rootfs>/bin`).
  - [ ] `toybox`:
    - [ ] Android-standard cleanroom BSD/POSIX implementation of core utilities.
  - [ ] Device managers for Musl:
    - [ ] `mdev` (BusyBox lightweight device manager).
    - [ ] `mdevd` (Skarnet fast netlink device daemon).
    - [ ] `eudev` compiled against Musl.

- [ ] **7.3 Static Linking & Footprint Optimization**
  - [ ] Build variants for full static binaries (`-static`).
  - [ ] Hardened GCC spec files for Musl (`hardenedgcc`).
  - [ ] Stripping all symbol tables and sections (`sstrip`).

---

## 8. Kernel, Initramfs & Firmware Subsystem

Provide automated source retrieval, configuration, compilation, and packaging of Linux kernels and
initramfs images. Ensure all orchestration scripts are POSIX `/bin/sh` with Windows batch parity,
strictly idempotent, and have 100% doc coverage.

- [ ] **8.1 Linux Kernel Compilation Engine (`_lib/kernel/linux/`)**
  - [ ] Provide `setup.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance, `STACK` guard) and `setup.cmd`
        (Windows batch equivalent).
  - [ ] Include `## Overview` and `## Usage` in the first 30 lines.
  - [ ] Automated download and cryptographic signature verification of kernel source tarballs
        (`kernel.org`).
  - [ ] Git checkout support for tracking specific branches (e.g., `linux-6.6.y`).
  - [ ] Configuration Fragment Merger:
    - [ ] Integrate `scripts/kconfig/merge_config.sh`.
    - [ ] Provide library of modular `.cfg` snippets:
      - [ ] `virtio.cfg`: `CONFIG_VIRTIO=y`, `CONFIG_VIRTIO_PCI=y`, `CONFIG_VIRTIO_BLK=y`,
            `CONFIG_VIRTIO_NET=y`.
      - [ ] `wayland_drm.cfg`: `CONFIG_DRM=y`, `CONFIG_DRM_KMS_HELPER=y`, `CONFIG_DRM_AMDGPU=y`,
            `CONFIG_DRM_I915=y`.
      - [ ] `zfs.cfg`: Kernel hooks for OpenZFS.
      - [ ] `sound.cfg`: `CONFIG_SOUND=y`, `CONFIG_SND=y`, `CONFIG_SND_HDA_INTEL=y`.
      - [ ] `containers.cfg`: `CONFIG_NAMESPACES=y`, `CONFIG_CGROUPS=y`, `CONFIG_OVERLAY_FS=y`.
  - [ ] Idempotent kernel compilation:
    - [ ] Verify if target kernel binary `<target-rootfs>/boot/vmlinuz-<version>` already exists and
          matches config hash.
    - [ ] `make -j$(nproc) bzImage modules dtbs`.
  - [ ] Kernel installation:
    - [ ] Copy kernel to `<target-rootfs>/boot/vmlinuz-<version>`.
    - [ ] Copy System.map to `<target-rootfs>/boot/System.map-<version>`.
    - [ ] Copy config to `<target-rootfs>/boot/config-<version>`.
    - [ ] Install modules: `make modules_install INSTALL_MOD_PATH=<target-rootfs>`.
    - [ ] Run `depmod -b <target-rootfs> <kernel-version>`.

- [ ] **8.2 Initramfs Generator (`_lib/kernel/initramfs/`)**
  - [ ] Implement `gen_initramfs.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance) and `gen_initramfs.cmd`
        (Windows batch equivalent):
    - [ ] 100% doc coverage (`## Overview` and `## Usage` in first 30 lines).
    - [ ] Idempotent CPIO generation: skip recompression if modules and init script are unchanged.
  - [ ] Pack minimal BusyBox/Toybox static binary into temporary tree using `mkdir -p` /
        `if not exist ... mkdir`.
  - [ ] Add device nodes: `/dev/null`, `/dev/console`, `/dev/tty`.
  - [ ] Include necessary kernel modules: storage drivers (`ahci`, `nvme`, `virtio_blk`,
        `virtio_pci`), filesystem drivers (`ext4`, `btrfs`, `xfs`), crypto modules (`dm-crypt`,
        `aes`).
  - [ ] Write robust pure POSIX `/bin/sh` `/init` script:
    - [ ] Mount `/dev`, `/proc`, `/sys`.
    - [ ] Parse kernel command line (`/proc/cmdline`) for `root=`, `rootfstype=`, `rootflags=`,
          `ro`, `rw`.
    - [ ] Support root device discovery by UUID (`UUID=...`) and PARTUUID.
    - [ ] Support LUKS decryption (`cryptsetup open <dev> root`).
    - [ ] Mount real root filesystem at `/newroot`.
    - [ ] Clean up mounts and pivot root: `exec switch_root /newroot /sbin/init "$@"`.
  - [ ] Compress into CPIO archive:
        `find . | cpio -H newc -o | zstd -19 > <target-rootfs>/boot/initramfs-<version>.img`.
  - [ ] Optional integration with `dracut` and `mkinitcpio`.

- [ ] **8.3 Hardware Firmwares (`_lib/kernel/firmware/`)**
  - [ ] Implement `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance and `STACK` guard.
  - [ ] Fetch official `linux-firmware` repository.
  - [ ] Implement smart firmware filtering to prevent disk image bloat:
    - [ ] Graphics firmware: AMDGPU (`amdgpu/*`), Intel i915/Xe (`i915/*`, `xe/*`), Nouveau
          (`nouveau/*`).
    - [ ] Wireless firmware: Intel Wi-Fi (`iwlwifi-*`), Realtek (`rtlwifi/*`), Atheros (`ath10k/*`,
          `ath11k/*`).
    - [ ] Audio firmware: Intel Sound Open Firmware (`intel/sof/*`).
  - [ ] Idempotently install selected firmwares to `<target-rootfs>/lib/firmware/`.

---

## 9. Init Systems & Service Managers

Provide clean integration recipes for all major Linux init systems. Every component must have paired
`setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch) scripts, 100% doc coverage, and
strictly idempotent service configuration.

- [ ] **9.1 `systemd` Integration (`_lib/init-systems/systemd/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance and `STACK` guard.
  - [ ] Compile `systemd` with Meson options matching `os-config.json`.
  - [ ] Idempotent unit enabling abstraction: `systemctl --root=<target-rootfs> enable <unit>`.
  - [ ] Configure default target: `systemctl --root=<target-rootfs> set-default graphical.target`
        (or `multi-user.target`).
  - [ ] Generate `/etc/systemd/journald.conf` and `/etc/systemd/logind.conf`.

- [ ] **9.2 `openrc` Integration (`_lib/init-systems/openrc/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance and `STACK` guard.
  - [ ] Compile `openrc` and install service scripts to `<target-rootfs>/etc/init.d/`.
  - [ ] Idempotent runlevel service helper:
        `rc-update --root=<target-rootfs> add <service> default`.
  - [ ] Provide standard init scripts: `bootmisc`, `hostname`, `modules`, `mount-ro`, `sysctl`,
        `udev`, `netmount`, `sshd`.
  - [ ] Generate `/etc/rc.conf`.

- [ ] **9.3 `sysvinit` Integration (`_lib/init-systems/sysvinit/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance and `STACK` guard.
  - [ ] Compile `sysvinit` (`init`, `halt`, `reboot`, `shutdown`, `telinit`).
  - [ ] Generate `/etc/inittab`:
    - [ ] Define `id:3:initdefault:` or `id:5:initdefault:`.
    - [ ] Configure system initialization: `si::sysinit:/etc/rc.d/init.d/rc sysinit`.
    - [ ] Configure virtual consoles: `1:2345:respawn:/sbin/agetty --noclear tty1 9600`.
  - [ ] Provide LFS-standard bootscripts in `/etc/rc.d/`.

- [ ] **9.4 `runit` & `s6` Integration (`_lib/init-systems/runit/`, `s6/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` for `runit` and `s6` with canonical `THIS_FILE=` dance.
  - [ ] Compile `runit` (`runit`, `runit-init`, `runsv`, `sv`, `svlogd`).
  - [ ] Setup `/etc/runit/1`, `/etc/runit/2`, `/etc/runit/3`.
  - [ ] Provide service directories in `/etc/sv/` and idempotently symlink active services into
        `/var/service/` (`ln -sf`).
  - [ ] For `s6`: configure `s6-rc` service database, compiled service graph, and
        `/etc/s6-rc/compiled`.

---

## 10. Graphics Stack & Display Hardware Acceleration

Provide full open-source and proprietary graphics driver pipelines. All recipes must provide paired
`setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=` dance, idempotency, and
100% doc coverage.

- [ ] **10.1 Direct Rendering Infrastructure (`_lib/graphics/`)**
  - [ ] **`libdrm`**:
    - [ ] Drivers: `intel`, `radeon`, `amdgpu`, `nouveau`, `vmwgfx`.
    - [ ] Build test programs: `modetest`, `vbltest`.
  - [ ] **`mesa`**:
    - [ ] Gallium drivers: `radeonsi`, `iris`, `crocus`, `nouveau`, `virgl`, `zink`, `swrast`
          (llvmpipe).
    - [ ] Vulkan drivers: `radv`, `anv`, `nouveau`, `lavapipe`, `virtio`.
    - [ ] Variants: `opengl`, `gles1`, `gles2`, `egl`, `gbm`, `dri3`, `wayland`, `x11`, `vaapi`.
    - [ ] Integration with LLVM/Clang for Gallium shader compilation.
  - [ ] **`vulkan-loader` & `vulkan-headers`**:
    - [ ] Khronos official Vulkan ICD loader.
    - [ ] Validation layers and `vulkaninfo` utility.
  - [ ] **`libva` & `libvdpau`**:
    - [ ] Video acceleration API libraries and tools (`vainfo`, `vdpauinfo`).
    - [ ] Hardware drivers: `intel-media-driver` (iHD), `libva-intel-driver` (i965),
          `mesa-va-drivers`.

- [ ] **10.2 Proprietary Drivers Support**
  - [ ] **`nvidia`**:
    - [ ] Automated kernel module compilation (`nvidia.ko`, `nvidia-modeset.ko`, `nvidia-drm.ko`,
          `nvidia-uvm.ko`).
    - [ ] Install proprietary EGL / OpenGL / Vulkan vendor ICD files (`10_nvidia.json`).
    - [ ] Install `nvidia-persistenced` and systemd service units.

---

## 11. Display Protocols: Wayland and X11 Server Stacks

Implement clean, modular separation between Wayland and X11 graphics subsystems. All recipes must
provide paired `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=` dance,
idempotency, and 100% doc coverage.

- [ ] **11.1 Wayland Core Protocol Stack (`_lib/display-servers/wayland/`)**
  - [ ] **`wayland`**:
    - [ ] `libwayland-client.so`, `libwayland-server.so`, `libwayland-cursor.so`,
          `libwayland-egl.so`.
    - [ ] `wayland-scanner` tool for C code generation from protocol XML.
  - [ ] **`wayland-protocols`**:
    - [ ] Install all stable, staging, and unstable protocol XML definitions.
  - [ ] **`libxkbcommon`**:
    - [ ] Core keyboard layout handling (`libxkbcommon`, `libxkbcommon-x11`).
    - [ ] Integration with `xkeyboard-config`.
  - [ ] **`seatd` / `libseat`**:
    - [ ] Rootless seat management daemon (`seatd`) and unified client library (`libseat`).
    - [ ] Systemd-free seat arbitration for non-systemd Wayland desktops.
  - [ ] **`wlroots`**:
    - [ ] Modular Wayland compositor backend abstraction library.
    - [ ] Build variants: `xwayland`, `libinput`, `session`.
  - [ ] **`xwayland`**:
    - [ ] Standalone X server running as a Wayland client for backward compatibility with legacy X11
          apps.

- [ ] **11.2 X11 Protocol Stack (`_lib/display-servers/xorg/`)**
  - [ ] **`xorg-server`**:
    - [ ] Build classic `Xorg` binary with SUID wrapper or rootless systemd logind support.
    - [ ] Configure Meson options: `-Ddri3=true`, `-Dglx=true`, `-Dxvfb=true`, `-Dxnest=true`.
  - [ ] **Core X11 Client Libraries**:
    - [ ] `libX11`, `libXext`, `libXrender`, `libXrandr`, `libXi`, `libXcursor`, `libXfixes`,
          `libXtst`, `libXinerama`, `libXpm`, `libXdamage`, `libXcomposite`.
  - [ ] **Input & Video Drivers**:
    - [ ] `xf86-input-libinput`: modern unified input driver for touchpads, mice, and keyboards.
    - [ ] `xf86-video-modesetting`: universal KMS driver.
    - [ ] `xf86-video-amdgpu`, `xf86-video-intel`, `xf86-video-nouveau`.
  - [ ] **X11 Utilities & Fonts**:
    - [ ] `xinit`, `xauth`, `xrdb`, `xset`, `xmodmap`, `xrandr`, `xdpyinfo`, `glxinfo`.
    - [ ] `font-util`, `mkfontscale`, `mkfontdir`, `bdftopcf`.
    - [ ] Core fonts: `dejavu-fonts`, `liberation-fonts`, `noto-fonts`.

---

## 12. Desktop Environments & Window Managers

Provide complete, automated compilation recipes for modern graphical desktops. All component recipes
must feature paired `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=`
dance, idempotency, and 100% doc coverage.

- [ ] **12.1 Wayland Tiling Compositors (`_lib/desktops/wayland/`)**
  - [ ] **`sway`**:
    - [ ] Build `sway` compositor against `wlroots`.
    - [ ] Companion packages: `swaybg` (wallpaper), `swayidle` (idle daemon), `swaylock` (PAM screen
          lock).
    - [ ] Status bar & launchers: `waybar`, `wofi`, `rofi-wayland`, `mako` (notification daemon).
    - [ ] Utilities: `grim` (screenshot), `slurp` (region selection), `wl-clipboard` (clipboard
          management).
  - [ ] **`hyprland`**:
    - [ ] Build `hyprland` dynamic tiling compositor.
    - [ ] Dependencies: `hyprland-protocols`, `hyprlang`, `hyprcursor`, `hyprutils`, `aquamarine`.
    - [ ] Companion packages: `hyprpaper`, `hyprlock`, `hypridle`, `dunst` / `swaync`.
  - [ ] **`weston`**:
    - [ ] Reference Wayland compositor with kiosk and desktop shells.

- [ ] **12.2 Full Desktop Suites (`_lib/desktops/`)**
  - [ ] **`xfce4`**:
    - [ ] Core libraries: `libxfce4util`, `xfconf`, `libxfce4ui`, `garcon`, `exo`.
    - [ ] Core components: `xfce4-panel`, `thunar`, `xfwm4` (or Labwc for Wayland), `xfce4-session`,
          `xfdesktop`, `xfce4-settings`.
    - [ ] Accessories: `xfce4-terminal`, `xfce4-appfinder`, `tumbler`, `xfce4-power-manager`.
  - [ ] **`lxqt`**:
    - [ ] Build tools: `lxqt-build-tools`.
    - [ ] Core Qt libraries: `libqtxdg`, `liblxqt`, `lxqt-qtplugin`, `lxqt-themes`.
    - [ ] Desktop components: `lxqt-session`, `lxqt-panel`, `pcmanfm-qt`, `lxqt-runner`,
          `lxqt-policykit`, `qterminal`.
    - [ ] Window manager: `openbox` (X11) or `labwc` (Wayland).
  - [ ] **`kde-plasma` (Plasma 6)**:
    - [ ] Core dependencies: Qt6 (base, declarative, wayland, svg, 5compat).
    - [ ] KDE Frameworks 6 (KF6): Tier 1, Tier 2, and Tier 3 libraries.
    - [ ] Workspace: `kwin` (Wayland/X11 compositor), `plasma-workspace`, `plasma-desktop`, `breeze`
          styling, `plasma-nm`, `plasma-pa`.
    - [ ] Core apps: `dolphin` (file manager), `konsole` (terminal), `kwrite` (text editor).
  - [ ] **`gnome`**:
    - [ ] Core foundations: `glib`, `gobject-introspection`, `gtk3`, `gtk4`, `libadwaita`,
          `gsettings-desktop-schemas`.
    - [ ] Shell & window manager: `mutter`, `gnome-shell`, `gnome-session`, `gnome-control-center`.
    - [ ] Services: `gvfs`, `tracker`, `gnome-settings-daemon`.

---

## 13. Display Managers, Session Greeters & Desktop Portals

Provide login screens, session handoffs, and sandboxed portal integration. All recipes must feature
paired `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=` dance,
idempotency, and 100% doc coverage.

- [ ] **13.1 Display Managers (`_lib/display-managers/`)**
  - [ ] **`greetd`**:
    - [ ] Compile `greetd` daemon.
    - [ ] Configure `tuigreet` (minimalist text console greeter).
    - [ ] Configure `gtkgreet` (Wayland graphical greeter).
    - [ ] Configure `/etc/greetd/config.toml` session commands.
  - [ ] **`sddm`**:
    - [ ] Compile `sddm` with Qt6 / QML greeters.
    - [ ] Configure Wayland compositor backend for SDDM (`kwin_wayland` or `weston`).
    - [ ] Configure `/etc/sddm.conf`.
  - [ ] **`gdm`**:
    - [ ] Compile `gdm` with native Wayland session arbitration.
    - [ ] Configure `/etc/gdm/custom.conf`.
  - [ ] **`lightdm`**:
    - [ ] Compile `lightdm` with GTK+ greeter (`lightdm-gtk-greeter`).
    - [ ] Configure `/etc/lightdm/lightdm.conf`.

- [ ] **13.2 Desktop Portals & Interoperability (`_lib/desktop-integration/`)**
  - [ ] `dbus`: System daemon (`/usr/bin/dbus-daemon --system`) and session bus setup.
  - [ ] `polkit`: Privilege escalation agent (`polkit-gnome` or `polkit-kde-agent-1`).
  - [ ] `xdg-desktop-portal`: Core portal daemon.
  - [ ] Backends:
    - [ ] `xdg-desktop-portal-wlr` (screen capture and screencasting for wlroots).
    - [ ] `xdg-desktop-portal-gtk` (GTK file chooser and notifications).
    - [ ] `xdg-desktop-portal-kde` (KDE Plasma portal integration).
  - [ ] `xdg-user-dirs`: Automated generation of standard user folders (`Desktop`, `Downloads`,
        `Documents`, `Music`, `Pictures`, `Videos`).

---

## 14. Audio & Multimedia Subsystems (PipeWire, PulseAudio, ALSA)

Implement modern sound server and video routing infrastructure. All recipes must feature paired
`setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=` dance, idempotency, and
100% doc coverage.

- [ ] **14.1 ALSA Base Stack (`_lib/audio/alsa/`)**
  - [ ] Compile `alsa-lib` and `alsa-utils` (`alsamixer`, `amixer`, `aplay`, `arecord`, `alsactl`).
  - [ ] Configure `/etc/asound.conf`.
  - [ ] Setup `alsa-state` / `alsa-restore` system service to preserve audio levels across reboots.
  - [ ] Install `alsa-ucm-conf` (Use Case Manager definitions) and `alsa-topology-conf`.

- [ ] **14.2 PipeWire Multimedia Graph (`_lib/audio/pipewire/`)**
  - [ ] Compile `pipewire` with Meson:
    - [ ] SPA plugins: `spa-alsa`, `spa-audioconvert`, `spa-bluez5`, `spa-v4l2`.
    - [ ] Modules: `module-pulse-tunnel`, `module-jack-tunnel`.
  - [ ] Compatibility libraries:
    - [ ] `pipewire-pulse` (PulseAudio client drop-in replacement).
    - [ ] `pipewire-jack` (JACK client drop-in replacement).
    - [ ] `pipewire-alsa` (ALSA PCM redirect plugin).
  - [ ] Session Manager:
    - [ ] Compile `wireplumber` modular session manager.
    - [ ] Configure policy hooks for default device switching and audio routing.
  - [ ] Service Orchestration:
    - [ ] Provide user units for systemd: `pipewire.service`, `pipewire-pulse.service`,
          `wireplumber.service`.
    - [ ] Provide user startup wrapper for OpenRC / runit / s6.

- [ ] **14.3 PulseAudio Classic Stack (`_lib/audio/pulseaudio/`)**
  - [ ] Compile `pulseaudio` daemon and `pactl` / `pacmd` utilities.
  - [ ] Configure `/etc/pulse/default.pa` (udev detection, ALSA sinks).

---

## 15. Networking, Wireless & System Security Services

Provide robust networking daemons, firewalls, and time synchronization. All recipes must feature
paired `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=` dance,
idempotency, and 100% doc coverage.

- [ ] **15.1 Networking Daemons (`_lib/networking/`)**
  - [ ] **`NetworkManager`**:
    - [ ] Full network stack with `nmcli`, `nmtui`, Wi-Fi backends, and VPN support.
  - [ ] **`systemd-networkd` & `systemd-resolved`**:
    - [ ] Minimalist network daemon with `/etc/systemd/network/*.network` declarative files.
  - [ ] **`iwd`**:
    - [ ] Modern lightweight Intel Wi-Fi daemon with `iwctl` CLI.
  - [ ] **`wpa_supplicant`**:
    - [ ] Standard WPA2/WPA3 enterprise Wi-Fi daemon with `wpa_cli`.
  - [ ] **`dhcpcd`**:
    - [ ] Lightweight, cross-platform DHCP/IPv6 client.

- [ ] **15.2 Firewalls & Security**
  - [ ] `nftables`: Modern packet filtering framework and `/etc/nftables.conf` rulesets.
  - [ ] `iptables`: Classic netfilter packet filtering (`iptables`, `ip6tables`).
  - [ ] `pf`: OpenBSD Packet Filter on FreeBSD.
  - [ ] Time synchronization: `chrony` (robust NTP client/server) or `systemd-timesyncd`.
  - [ ] Remote access: `openssh` server (`sshd`) with hardened `/etc/ssh/sshd_config`.

---

## 16. Target Package Manager Integration (Porg, Pacman, Apk, Dpkg, Pkg, Xbps)

Support embedding a functioning package manager into the generated OS so it can be maintained after
installation. All recipes must feature paired `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows
batch), `THIS_FILE=` dance, idempotency, and 100% doc coverage.

- [ ] **16.1 Porg (Package Organizer - jhalfs native standard)**
  - [ ] Compile `porg` with `LD_PRELOAD` logging support.
  - [ ] Wrap package installations inside `porg -lp <package-version>` to track installed files in
        `<target-rootfs>/var/lib/porg/`.

- [ ] **16.2 Arch `pacman` Integration**
  - [ ] Bootstrap `pacman` database inside target rootfs (`pacman-db-upgrade`).
  - [ ] Populate `/etc/pacman.conf` and repository mirrors.
  - [ ] Register installed packages into local database `/var/lib/pacman/local/`.

- [ ] **16.3 Alpine `apk` Integration**
  - [ ] Bootstrap `apk-tools` static binary.
  - [ ] Initialize `/etc/apk/repositories` and `/etc/apk/world`.
  - [ ] Populate installed package database via `apk add --root=<target-rootfs> --initdb`.

- [ ] **16.4 Debian `dpkg` / `apt` Integration**
  - [ ] Initialize `/var/lib/dpkg/status` and administrative directory.
  - [ ] Configure `/etc/apt/sources.list`.

- [ ] **16.5 Void `xbps` Integration**
  - [ ] Initialize target XBPS database via `xbps-install -r <target-rootfs> -S`.

---

## 17. FreeBSD Distribution Subsystem (World, Kernel, Jails, ZFS)

Provide full native support for building FreeBSD releases, custom kernels, ZFS pools, and
lightweight jail images. All orchestration scripts must feature paired `setup.sh` (POSIX `/bin/sh`)
and `setup.cmd` (Windows batch), `THIS_FILE=` dance, idempotency, and 100% doc coverage.

- [ ] **17.1 Source Acquisition & Build Infrastructure (`_lib/freebsd/`)**
  - [ ] Provide `setup.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance, `STACK` guard) and `setup.cmd`
        (Windows batch).
  - [ ] 100% doc coverage (`## Overview` and `## Usage` in first 30 lines).
  - [ ] Automated git checkout of FreeBSD source tree (`git.freebsd.org/src.git` or release
        tarballs).
  - [ ] Configuration knob generators:
    - [ ] `/etc/make.conf` (compiler flags, optimization).
    - [ ] `/etc/src.conf` (knobs: `WITHOUT_X11`, `WITHOUT_TESTS`, `WITHOUT_CLANG`, `WITH_BEARSSL`).
  - [ ] **`buildworld` / `installworld` orchestration**:
    - [ ] Execute `make -j$(nproc) buildworld` with `MAKEOBJDIRPREFIX` isolation and idempotent
          stamp checks.
    - [ ] Execute `make installworld DESTDIR=<target-rootfs>`.
    - [ ] Execute `make distribution DESTDIR=<target-rootfs>` (populate default `/etc`, `/var`).
  - [ ] **`buildkernel` / `installkernel` orchestration**:
    - [ ] Support custom `KERNCONF` files.
    - [ ] Execute `make -j$(nproc) buildkernel KERNCONF=MYKERNEL`.
    - [ ] Execute `make installkernel DESTDIR=<target-rootfs> KERNCONF=MYKERNEL`.

- [ ] **17.2 FreeBSD System Configuration**
  - [ ] Automated `/etc/rc.conf` generation (hostname, network interfaces, daemons:
        `sshd_enable="YES"`, `zfs_enable="YES"`).
  - [ ] Automated `/boot/loader.conf` generation (kernel modules: `zfs_load="YES"`,
        `vfs.root.mountfrom`, console baud rate).
  - [ ] Automated `/etc/fstab` generation.
  - [ ] Non-interactive bootstrap of `pkg` into target rootfs
        (`ASSUME_ALWAYS_YES=yes pkg -r <target-rootfs> bootstrap`).
  - [ ] Automated package installation via `pkg -r <target-rootfs> install -y <packages>`.

- [ ] **17.3 FreeBSD Storage & ZFS Partitioning**
  - [ ] Partitioning via `gpart`:
    - [ ] GPT partitioning scheme with `freebsd-boot` (BIOS), `efi` (UEFI), and `freebsd-zfs` or
          `freebsd-ufs`.
  - [ ] Automated ZFS root pool creation (`zpool create -R <target-rootfs> zroot <dev>`).
  - [ ] Dataset hierarchy: `zroot/ROOT/default`, `zroot/home`, `zroot/var`, `zroot/tmp`.
  - [ ] Bootloader installation: write `pmbr` and `gptzfsboot` (or EFI loader `loader.efi`).

- [ ] **17.4 FreeBSD Jail Templates**
  - [ ] Generate minimal, thin jail root filesystems.
  - [ ] Templating `/etc/jail.conf` with VNET network virtualization.

---

## 18. Unikernel & MicroVM Subsystems (Unikraft, OSv, MirageOS, Firecracker)

Provide specialized single-address-space kernels and microVM roots for high-density cloud, edge, and
serverless computing. All blueprint recipes must feature paired `setup.sh` (POSIX `/bin/sh`) and
`setup.cmd` (Windows batch), `THIS_FILE=` dance, idempotency, and 100% doc coverage.

- [ ] **18.1 Unikraft Integration (`_lib/unikernels/unikraft/`)**
  - [ ] Provide `setup.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance) and `setup.cmd` (Windows batch).
  - [ ] Integrate Unikraft core build system and library repository ecosystem (`kraft` / Make).
  - [ ] Target platforms: `kvm` (QEMU/Firecracker), `xen`, `linuxu` (userspace execution).
  - [ ] Target architectures: `x86_64`, `aarch64`.
  - [ ] Core Unikraft micro-libraries: `nolibc`, `musl`, `ukboot`, `ukalloc`, `uksched`, `uklock`,
        `lwip` (TCP/IP), `vfscore`, `ramfs`, `9pfs`.
  - [ ] Application blueprints:
    - [ ] Static C/C++ binary embedding.
    - [ ] Python/Lua/Node.js runtime unikernel image.
    - [ ] Web servers: Nginx, Redis.
  - [ ] Output artifact: standalone bootable ELF image (`unikraft.bin` / `unikraft.elf`).

- [ ] **18.2 OSv Integration (`_lib/unikernels/osv/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance.
  - [ ] Automated build of OSv kernel from source (`make -j$(nproc)`).
  - [ ] Manifest packager: inject user application payloads (Java JAR, Go binary, Node.js app) into
        OSv `usr.manifest`.
  - [ ] Output artifact: bootable QCOW2 or raw disk image (`osv.img`).

- [ ] **18.3 MirageOS & Solo5 Integration (`_lib/unikernels/mirage/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance.
  - [ ] Support MirageOS OCaml unikernel build flow.
  - [ ] Solo5 tender integration: `solo5-hvt` (hardware virtualized), `solo5-spt` (sandboxed
        seccomp).

- [ ] **18.4 MicroVM Kernel & Rootfs Targets (Firecracker / Cloud-Hypervisor)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance.
  - [ ] Compile uncompressed minimal Linux kernel (`vmlinux`) stripped of PCI, ACPI, USB, and IDE
        drivers, enabling only `virtio-net`, `virtio-block`, `virtio-vsock`.
  - [ ] Generate ultra-minimal read-only rootfs (ext4 or squashfs) containing only user service and
        dependencies, booting to userspace in < 15ms.

---

## 19. Storage, Partitioning, Filesystems & Encryption

Provide automated image formatting, partitioning, filesystem population, and bootloader
configuration. All provisioning scripts must be strictly idempotent, implemented in pure POSIX
`/bin/sh` and Windows batch, and feature 100% doc coverage.

- [ ] **19.1 Virtual Disk Provisioning & Partitioning (`_lib/storage/`)**
  - [ ] Implement `provision_disk.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance, `STACK` guard) and
        `provision_disk.cmd` (Windows batch equivalent).
  - [ ] Both scripts include `## Overview` and `## Usage` in the first 30 lines.
  - [ ] Idempotent loopback device allocation: check if image is already mapped
        (`losetup -j <disk.img>`).
  - [ ] Scripted non-interactive partitioning using `sfdisk` or `parted`:
    - [ ] Check if valid partition table already exists before attempting repartitioning to avoid
          data loss.
    - [ ] Modern UEFI: GPT partition table, EFI System Partition (FAT32, type
          `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`), Root partition.
    - [ ] Legacy BIOS: MBR table or GPT with BIOS Boot Partition
          (`21686148-6449-6E6F-744E-656564454649`).
    - [ ] Hybrid UEFI/BIOS: Both ESP and BIOS boot partitions on GPT.
  - [ ] Full disk encryption:
    - [ ] Idempotent LUKS setup: verify if container is already formatted
          (`cryptsetup isLuks <partition>`).
    - [ ] LUKS2 format setup: `cryptsetup luksFormat --type luks2 --pbkdf argon2id <partition>`.
    - [ ] Mapper opening: `cryptsetup open <partition> cryptroot`.
    - [ ] Automated `/etc/crypttab` creation.

- [ ] **19.2 Filesystem Formatting & Populate**
  - [ ] Implement `format_fs.sh` (POSIX `/bin/sh`, `THIS_FILE=` dance) and `format_fs.cmd` (Windows
        batch equivalent).
  - [ ] Idempotent formatters (check `blkid` before formatting):
    - [ ] `mkfs.ext4 -F -L ROOT <dev>`
    - [ ] `mkfs.btrfs -L ROOT <dev>` (create subvolumes: `@`, `@home`, `@var`, `@snapshots`)
    - [ ] `mkfs.xfs -f -L ROOT <dev>`
    - [ ] `mkfs.vfat -F32 -n EFI <dev>`
    - [ ] `zpool create` and ZFS dataset hierarchies.
  - [ ] Populate target filesystem: high-speed copy of assembled sysroot into mounted target
        (`rsync -aHAX <rootfs>/ <mountpoint>/`).
  - [ ] Automated `/etc/fstab` generation based on persistent partition UUIDs (`blkid`).

---

## 20. Bootloaders, EFI Stubs & Unified Kernel Images (UKI)

Implement bootloader installation, unified kernel images, and Secure Boot signing. All recipes must
feature paired `setup.sh` (POSIX `/bin/sh`) and `setup.cmd` (Windows batch), `THIS_FILE=` dance,
idempotency, and 100% doc coverage.

- [ ] **20.1 Bootloader Installation (`_lib/bootloaders/`)**
  - [ ] Provide `setup.sh` and `setup.cmd` with canonical `THIS_FILE=` dance and `STACK` guard.
  - [ ] 100% doc coverage (`## Overview` and `## Usage`).
  - [ ] **GRUB2**:
    - [ ] EFI installation:
          `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=libscript`.
    - [ ] BIOS installation: `grub-install --target=i386-pc /dev/loopX`.
    - [ ] Idempotent `grub.cfg` generation without host contamination.
  - [ ] **systemd-boot**:
    - [ ] Installation to ESP: `bootctl --esp-path=/boot/efi install`.
    - [ ] Loader configuration `/boot/loader/loader.conf` and entries `/boot/loader/entries/*.conf`.
  - [ ] **Limine**:
    - [ ] Installation of Limine EFI and BIOS binaries (`limine bios-install /dev/loopX`).
    - [ ] Generation of `limine.conf`.

- [ ] **20.2 Unified Kernel Image (UKI) & Secure Boot**
  - [ ] Combine kernel, initramfs, cmdline, and os-release using `systemd-stub` or `ukify`.
  - [ ] Install single `.efi` binary directly into `/boot/efi/EFI/Linux/`.
  - [ ] Secure Boot signing using custom PK, KEK, and db keys via `sbsign`.

---

## 21. Bootable Output Formats (`package-as`)

Extend `./libscript.sh package-as` and `libscript.cmd package-as` with targets that output complete,
ready-to-deploy operating system media. All packaging format modules must provide paired `.sh`
(POSIX `/bin/sh`) and `.cmd` (Windows batch) scripts, `THIS_FILE=` dance, idempotency, and 100% doc
coverage.

- [ ] **21.1 `package-as raw-img` (Raw Bootable Disk Image)**
  - [ ] Implement `cli/commands/package_as/raw_img.sh` and `raw_img.cmd`.
  - [ ] Generate partitioned disk image (`.img`) containing bootloader, kernel, and populated
        rootfs.
  - [ ] Sparse file handling (`truncate -s <size>G target.img`) and image shrinking (`e2fsck` +
        `resize2fs`).
  - [ ] Ready for direct flashing to physical drives
        (`dd if=target.img of=/dev/sdX bs=4M status=progress`).

- [ ] **21.2 `package-as qcow2` / `vmdk` / `vdi` (Virtual Machine Disks)**
  - [ ] Implement `cli/commands/package_as/vm_disk.sh` and `vm_disk.cmd`.
  - [ ] Convert raw image to QEMU QCOW2 with compression
        (`qemu-img convert -O qcow2 -c target.img target.qcow2`).
  - [ ] Convert to VMware VMDK (`qemu-img convert -O vmdk target.img target.vmdk`).
  - [ ] Convert to VirtualBox VDI (`qemu-img convert -O vdi target.img target.vdi`).

- [ ] **21.3 `package-as iso` (Live Bootable Media)**
  - [ ] Implement `cli/commands/package_as/iso.sh` and `iso.cmd`.
  - [ ] Compress rootfs into `rootfs.squashfs` with `mksquashfs` (`-comp zstd`).
  - [ ] Configure OverlayFS for ephemeral live sessions with copy-on-write RAM scratchpad.
  - [ ] Setup ISOLINUX and GRUB EFI El Torito boot catalogs.
  - [ ] Generate hybrid ISO using `xorriso` bootable on both legacy BIOS and UEFI.

- [ ] **21.4 `package-as rootfs-tar` (Container / Jail Base)**
  - [ ] Implement `cli/commands/package_as/rootfs_tar.sh` and `rootfs_tar.cmd`.
  - [ ] Archive clean rootfs into `rootfs.tar.xz` or `rootfs.tar.zst`.
  - [ ] Ready for direct import into Docker (`docker import rootfs.tar.xz my-os:latest`), Podman,
        LXC, or systemd-nspawn.

- [ ] **21.5 `package-as bsd-img` (FreeBSD Bootable Image)**
  - [ ] Implement `cli/commands/package_as/bsd_img.sh` and `bsd_img.cmd`.
  - [ ] Generate bootable UFS/ZFS FreeBSD image compatible with bhyve, QEMU, or bare-metal boot.

- [ ] **21.6 `package-as unikernel` (MicroVM Direct Boot)**
  - [ ] Implement `cli/commands/package_as/unikernel.sh` and `unikernel.cmd`.
  - [ ] Output standalone kernel binary (`vmlinux` / `unikraft.bin`) configured for direct boot in
        Firecracker or Cloud-Hypervisor.

---

## 22. Automated Emulation, Headless Boot Verification & CI Matrix

Ensure rigorous, end-to-end reliability by executing automated test harnesses against generated
images, verifying idempotency, and enforcing standards compliance. NEVER run `git push`.

- [ ] **22.1 Headless QEMU Verification Harness (`tests/os_boot_test.sh` and
      `tests/os_boot_test.cmd`)**
  - [ ] Enforce POSIX `/bin/sh` in `tests/os_boot_test.sh` and Windows batch equivalent in
        `tests/os_boot_test.cmd`.
  - [ ] Include canonical `THIS_FILE=` dance, `STACK` recursion guard, and `## Overview` /
        `## Usage` in first 30 lines.
  - [ ] Launch generated disk image headless in QEMU with serial console redirected to pipe.
  - [ ] Monitor serial console output for expected boot milestones:
    - [ ] Linux: Kernel banner -> Init system start -> Login prompt reached within timeout (e.g.,
          60s).
    - [ ] FreeBSD: Loader -> Kernel probe -> Multi-user login prompt.
    - [ ] Unikernel: Application banner output within 1s.
  - [ ] Automated pass/fail return code with serial log capture on failure.

- [ ] **22.2 Graphical Desktop Headless Smoke Tests**
  - [ ] Implement `tests/os_gui_smoke_test.sh` and `tests/os_gui_smoke_test.cmd`.
  - [ ] Launch graphical OS image in QEMU with `virtio-gpu-pci` and headless display
        (`-display none` or VNC loopback).
  - [ ] Wayland smoke test: assert Sway/Weston process starts and binds Wayland socket
        `/run/user/1000/wayland-0`.
  - [ ] Audio smoke test: assert PipeWire daemon starts and creates runtime sockets.

- [ ] **22.3 Multi-Platform Host Build Matrix**
  - [ ] Verify building Glibc Linux targets from Linux hosts.
  - [ ] Verify building Musl Linux targets from Linux hosts.
  - [ ] Verify building FreeBSD targets from Linux hosts (via QEMU bootstrap) and native FreeBSD
        hosts.
  - [ ] Verify building Linux, Musl, and Unikernel targets from macOS hosts (via containerized/VM
        builders).
  - [ ] Verify building and configuring targets from Windows hosts using native batch `.cmd`
        scripts.

- [ ] **22.4 LibScript Standards & Quality Audit Verification Matrix**
  - [ ] Execute `devtools/audit/audit_standards.sh` and `devtools/audit/audit_standards.cmd` against
        all created scripts.
  - [ ] Verify 100% compliance on:
    - [ ] `POSIX_SHEBANG`: Pure `#!/bin/sh` shebang, zero bash/zsh dependencies.
    - [ ] `THIS_FILE_DANCE`: Canonical `THIS_FILE=` path resolution in first 65 lines.
    - [ ] `RECURSION_GUARD`: `STACK` recursion guard in first 65 lines.
    - [ ] `WINDOWS_PARITY`: Exact paired `.cmd` (or `.bat`) equivalent for every `.sh` script.
    - [ ] `BATCH_THIS_FILE`: `set "THIS_FILE=%~f0"` in first 25 lines of batch scripts.
    - [ ] `IDEMPOTENCY`: No unguarded `mkdir` without `-p`; no unguarded `ln -s` without `-f`; all
          batch `mkdir` wrapped in `if not exist ...`.
    - [ ] `BAN_EVAL`: Zero disallowed uses of `eval` or `Invoke-Expression`.
    - [ ] `DOC_OVERVIEW` & `DOC_USAGE`: 100% documentation coverage with `## Overview` and
          `## Usage` in first 30 lines.

- [ ] **22.5 End-to-End Idempotency Verification (2x Run Test)**
  - [ ] Execute the entire synthesis and verification pipeline twice consecutively on identical
        workspaces.
  - [ ] Assert the second pass produces zero-op / no-op results without re-downloading,
        re-compiling, or mutating state.
  - [ ] Assert return code 0 and zero diff on target image / rootfs outputs.

- [ ] **22.6 Git Safety & Remote Repository Invariant**
  - [ ] Mandate that test harnesses, build pipelines, and CI jobs NEVER invoke `git push` under any
        condition.
