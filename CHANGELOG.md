# Changelog

All notable changes to the LibScript framework are documented here.

## [Unreleased]

### Added

- **Tiered Architecture & Universal OS Synthesis Framework**:
  - **Tier 1: Leaf Recipes, Cross-Toolchains & Native Version Management (`_lib/`)**:
    - Codified the Standard Context Contract (`LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
      `LIBSCRIPT_OFFLINE`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_TARGET_ARCH`, `LIBSCRIPT_TARGET_LIBC`,
      `LIBSCRIPT_TARGET_OS`, `LIBSCRIPT_TARGET_TRIPLET`).
    - Multi-stage cross-toolchain bootstrapping: Stage 0 host-driven cross-compiler coordinator
      (`_lib/toolchains/bootstrap/stage0.sh` / `.cmd`) building Binutils Pass 1, standalone GCC Pass
      1, Linux API headers, Target LibC, and cross-GCC Pass 2 into `/tools`.
    - Stage 1 minimal standalone POSIX userland bootstrap (`_lib/toolchains/bootstrap/stage1.sh` /
      `.cmd`) linked strictly to `/tools/lib/libc.so`.
    - Standard architecture triplet resolver (`_lib/toolchains/triplets.sh` / `.cmd`) for `x86_64`,
      `aarch64`, `riscv64`, and `i686` with `glibc`, `musl`, or `bsd-libc`.
    - Complete base-system catalog: Glibc (with `localedef` and dynamic linker), Musl, BusyBox,
      Toybox, Coreutils, `e2fsprogs`, `btrfs-progs`, `xfsprogs`, `eudev`, PAM, and Shadow.
    - Graphics, display servers, and desktops: `libdrm`, Mesa Gallium/Vulkan, `vulkan-loader`,
      Wayland, `wayland-protocols`, `wlroots`, `seatd`, `xorg-server`, `xwayland`, Sway, Hyprland,
      KDE Plasma 6, XFCE4, LXQt, Weston, and display greeters (`greetd`, `sddm`, `gdm`, `lightdm`).
    - Audio & networking subsystems: PipeWire multimedia graph router, WirePlumber, ALSA,
      NetworkManager, `systemd-networkd`, `iwd`, `wpa_supplicant`, `dhcpcd`, `nftables`, `iptables`,
      and OpenSSH.
    - Unified toolchain version management (`ls-remote`, `install`, `ls`, `use`, `uninstall`) for
      Node.js, Python, Rust, Ruby, Go, Java, PHP, and databases with per-shell PATH isolation.
  - **Tier 2: Synthesizers, Assemblers & Image Builders**:
    - Formalized declarative OS configuration schema (`os-config.schema.json`) and execution plan
      schema (`execution-plan.schema.json`).
    - Interactive terminal configurator and TUI engine (`cli/commands/config/config.sh` / `.cmd`,
      `tui_engine.sh` / `.cmd`) with ANSI VT100 / dialog / whiptail support.
    - Curated profile templates in `profiles/`: minimal headless Musl, standard Glibc server,
      Wayland Sway/Hyprland desktops, KDE Plasma 6, FreeBSD ZFS server/desktop, Firecracker microVM,
      and Unikraft/OSv unikernels.
    - Isolated rootfs staging (`_lib/orchestration/create_fhs_layout.sh` / `.cmd`, `rootfs.sh` /
      `.cmd`) with merged and split `/usr` support.
    - Virtual kernel filesystem lifecycle (`_lib/orchestration/vfs/mount_target_vfs.sh` /
      `umount_target_vfs.sh`) with idempotent mounting and automated signal traps.
    - Storage and partition provisioning (`_lib/storage/provision_disk.sh` / `.cmd`) supporting GPT,
      MBR, ESP, and LUKS2 `argon2id` encryption.
    - Multi-filesystem formatting engine (`_lib/storage/format_fs.sh` / `.cmd`) for Ext4, Btrfs
      subvolumes (`@`, `@home`, `@snapshots`), XFS, VFAT, and ZFS.
    - Linux kernel compilation and modular configuration fragment merger
      (`_lib/kernel/linux/setup.sh` / `.cmd`), CPIO initramfs builder
      (`_lib/kernel/initramfs/gen_initramfs.sh` / `.cmd`), and Unified Kernel Image (UKI)
      generation.
    - FreeBSD Kernel & World synthesis (`_lib/freebsd/setup.sh` / `.cmd`) with isolated
      `MAKEOBJDIRPREFIX` boundaries and ZFS-on-root loader configuration.
    - Bootloader installation (`_lib/bootloaders/setup.sh` / `.cmd`) for GRUB2 (UEFI/BIOS),
      `systemd-boot`, and Limine.
    - Universal media packaging via `package-as`: `raw-img`, `qcow2`, `vmdk`, `vdi`, `hyperv-vhd`,
      `proxmox-template`, `aws-ami`, `azure-vhd`, `gcp-image`, hybrid live `iso` (SquashFS +
      OverlayFS), `rootfs-tar`, `docker`, `bsd-img`, `illumos-distro`, direct-kernel `unikernel`,
      Windows `.msi` / `innosetup` / `nsis`, macOS `.pkg` / `.dmg`, Debian `.deb`, Red Hat `.rpm`,
      Alpine `.apk`, and FreeBSD `.txz`.
  - **Tier 3: Operators & Multicloud Deployers (`_lib/cloud-providers/`)**:
    - Multicloud VM and resource lifecycle management for AWS EC2, GCP Compute Engine, Azure
      Compute, Proxmox VE, Hetzner Cloud, and Vagrant.
    - MicroVM and unikernel execution drivers for Firecracker, Cloud-Hypervisor, and Solo5.
    - AI and hardware acceleration infrastructure: TPU VM automation (`ml-eval-node`) with GCS FUSE
      and TensorBoard, distributed TPU training via GKE + XPK, and high-throughput LLM inference
      deployments (`vLLM`, `JetStream`, `Ollama`).
    - Built-in PaaS & universal reverse proxying via `netctl` for Nginx, Caddy, Apache, and Windows
      IIS with automated Let's Encrypt TLS and OS init supervision (`systemd`, `launchd`, Windows
      Services).
    - Programmatic REST API and OpenAPI 3.0 control plane via `libscript-rest-api`.
  - **Declarative Constraint Solver & Tarjan SCC Cycle Breaking**:
    - Extended manifest schema (`manifest.schema.json`) with USE flag variants (`configure_args`,
      `meson_args`, `cmake_args`, `cflags`, `ldflags`) and dependency classifications (`host_tools`,
      `build_deps`, `runtime_deps`, `tier`).
    - Deterministic dependency resolution and circular dependency cycle-breaking using Tarjan's
      Strongly Connected Components (SCC) algorithm in `_lib/orchestration/resolve_stack.jq`.
  - **Cross-Platform Standards & Quality Invariants**:
    - Strict POSIX `/bin/sh` compliance and 100% Windows Batch (`.cmd`) parity with canonical
      `THIS_FILE=` path resolution and re-entrant `STACK` recursion guards.
    - Option A Win32 Hard-Fail Boundary Proforma (exit code `86` / `EX_UNAVAILABLE` / `ENOSYS`) on
      Windows for Linux kernel primitives, delegating to VM/Docker builders.
    - Static audit validation toolchain (`devtools/audit/audit_standards.sh` / `.ps1`).
    - Comprehensive verification matrix: headless QEMU boot tests (`tests/os_boot_test.sh` / `.cmd`,
      `freebsd_boot_test.sh`, `illumos_boot_test.sh`), graphical Wayland/PipeWire smoke tests
      (`tests/os_gui_smoke_test.sh` / `.cmd`), air-gapped boot tests (`tests/test_airgap_boot.sh` /
      `.cmd`), live installer matrix (`tests/test_live_installer_matrix.sh`), and 2x consecutive
      execution idempotency tests (`tests/test_idempotency_matrix.sh` / `.cmd`).
    - Continuous test result aggregation and automated `README.md` compatibility table
      synchronization via `tests/update_results.sh` / `.cmd` / `.ps1`.
    - Repository safety invariant: automated test suites and CI workflows strictly ban `git push`.
- Added support for `pkgx` and `vfox` as valid universal version manager fallbacks.
- Re-architected component method resolution with a smart fallback priority chain:
  `libscript_native` -> `mise` -> `asdf` -> `pkgx` -> `vfox` -> `system`.

### Completed Initiatives

#### Phase 9: Native REST API & OpenAPI 3.0 Control Plane

- High-performance C++ HTTP microservice daemon in `libscript-rest-api/`.
- Strongly typed OpenAPI 3.0 specification (`libscript-rest-api/openapi.yaml`).
- REST endpoints for remote component installation, stack synthesis, packaging execution, and log
  streaming.
- CMake build configuration and platform daemon service scripts.

#### Phase 8: Universal Live-CD / Live-USB Multiboot Installer (`msi-rs`)

- Declarative live execution schema (`execution-plan.live.schema.json`).
- Live media builder (`devtools/build_live_installer.sh` / `.cmd`) and USB flasher
  (`devtools/write_usb.sh` / `.cmd`).
- Tri-modal operator experience: Headless unattended (`msiexec`), curses TUI wizard, and fullscreen
  kiosk GUI (`msi-gui` on Wayland/X11).
- Multiboot co-installation across Linux, FreeBSD, and illumos with bootloader chaining.
- Automated screenshot verification harness (`devtools/capture_msi_live_screenshots.sh`).
- Architecture and operator guide in [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).

#### Phase 7: Illumos-Based Modular Distribution & Verification Matrix

- Declarative profile schema (`execution-plan.illumos.schema.json`) and 7 curated profiles.
- Pluggable init systems (`smf`, `runit`, `s6`, `dinit`, `inittab-sysv`) and desktop environments
  (MATE, XFCE4, CDE).
- Canonical ZFS root pool (`rpool`) hierarchy, boot environment management (`beadm`), and
  `/etc/vfstab` integration.
- Solaris Boomer in-kernel audio (`/dev/audio`), OSS, and PulseAudio support.
- Multi-format packaging: Raw GPT/VTOC, QCOW2, Vagrant `.box`, VHD, VMDK, ISO.
- 5-platform Vagrant verification matrix across `{macOS, Windows, FreeBSD, SunOS, Linux}`.

#### Phase 6: FreeBSD-Based Modular Distribution & Verification Matrix

- Specification & schema (`execution-plan.freebsd.schema.json`) with modular profiles.
- Pluggable Init Systems (`bsd-rc`, `openrc`, `runit`, `s6`, `dinit`).
- Display & Desktop modular staging (Wayland, X11, Sway, XFCE4, Plasma 6, seatd, PipeWire).
- Multi-format disk image export (Raw GPT, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- Headless boot, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency test harness.
- Vagrant-only multi-platform verification matrix across `{macOS, Windows, FreeBSD, SunOS, Linux}`.

#### Phase 5: AI & Machine Learning Infrastructure

- Introduced multi-cloud primitives for Google Cloud TPUs and GPU VMs.
- Added comprehensive AI serving and ML training stacks (vLLM, JetStream, XPK, GKE).
- Built-in data ingestion abstractions including `gcsfuse` and `tmux` execution persistence.

#### Phase 2: Multicloud PaaS Orchestration

- Unified `cloud` wrapper for AWS, Azure, and GCP utilizing native orchestration primitives (e.g.,
  Azure VNets, NSGs, and VMs).
- Replaced legacy `setup_ingress.sh` calls with `netctl`, a robust universal routing abstraction.
- Resource tagging and filtered cleanup for managed stacks.
- Node-group provisioning with automated stack bootstrapping.
- Intelligent application deployment (codebase sync, DNS mapping, secrets management).
- Declarative PaaS lifecycle management via `libscript.json`.
- Sidecar service injection (Logging, Monitoring).

#### Phase 1: Core Stability & Decentralized Management

- Zero-dependency POSIX and Windows core.
- "Every-Thing-is-a-Package-Manager" decentralized architecture.
- Automated stack resolution engine with version constraints.
- Support for major Windows and Linux installer formats.
