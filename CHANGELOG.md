# Changelog

All notable changes to the LibScript framework are documented here.

## [Unreleased]

### Added

- **Six-Tier (`T0`–`T5`) & Orthogonal Planes (`Plane A`, `Plane B`) Clean-Break Architecture**:
  - Replaced fractional tiers (`Tier 1.5`, `Tier 3.5`) and legacy cross-layer paths with 6 strictly
    ordered compositional tiers (`T0` `engine/`, `T1` & `T2` atomic `_lib/`, `T3` `synthesis/`, `T4`
    `infrastructure/`, `T5` `workloads/`) and 2 orthogonal planes (`Plane A` `traits/`, `Plane B`
    `experiments/` & `libscript-rest-api/`), enforced statically by
    `devtools/audit/audit_tiers.{sh,cmd}`.
  - Split `T4` cluster substrates
    (`infrastructure/clusters/{k0s-ha,gke-tpu-cluster,k8s-marathon-paas,mesos-marathon-ha,kubernetes-thw}`)
    from `T5` stateful service constellations
    (`workloads/constellations/{postgres-ha,redis-cluster,valkey-cluster,minio-distributed,openedx-ha,openedx-unikernel-pod,iot-mqtt-edge-pod}`),
    backed by `T0` `engine/consensus/{lock,fence}.{sh,cmd}`.
  - Unified all OS profiles, VFS sysroot scripts, disk formatters, distro builders, and `package-as`
    drivers under `T3` `synthesis/`, and decomposed `base_vars.schema.json` into domain schema packs
    (`schemas/vars/*.schema.json`).
- **Native Windows (PE) & MS-DOS (`dos32`) Component-Level Package Managers (`_lib/utilities/`,
  `depends`)**:
  - Target-aware `msdos` (`IS_MSDOS=1`, `PKG_MGR=libscript`) detection in
    `engine/common/os_info.{sh,cmd}` and `engine/common/pkg_map.tsv` routing across 6 standalone
    utilities (`jq`, `gawk`, `busybox`, `toybox`, `dash`, and `freebsd-usr-bin`) plus
    `_lib/toolchains/openwatcom/`, staging `dos32` + `DOS32A.EXE` binaries on MS-DOS and native PE
    (`X64`/`X86`/`ARM64`) binaries on Windows.
  - Pre-configured Vagrant environments for `vagrant/{freedos-1.4,msdos-1.25,msdos-2.0,msdos-4.0}/`
    and hermetic verification harness `tests/test_win_dos_component_pm.{sh,cmd}`.
- **Declarative `installer-e2e` Experiment Substrate & `experiments/openedx/` (`Plane B`)**:
  - Zero-code cross-OS installer and guest-UI evaluation runner
    (`experiments/_common/pkg_ui_runner.{sh,cmd}`,
    `experiments/schemas/installer-experiment.schema.json`),
    `./libscript.sh experiment scaffold <app> --template=installer-e2e`, and built-in
    `experiments/openedx/` suite.
- **Built-in FreeDOS (`1.3`, `1.4`) & MIT MS-DOS (`1.25`, `2.0`, `4.00`) Base Kernel & Modular
  Distribution Synthesis (`synthesis/distro/dos/`, `freedos`, `msdos`, `win-cmd-asm`,
  `win-cmd-rs`)**:
  - Declarative `synthesis/schemas/execution-plan.dos.schema.json` and 4 reference profiles under
    `synthesis/profiles/dos/` spanning `dos32-dpmi` (`freedos-1.4-djgpp-i586`,
    `msdos-4.0-djgpp-i586`), `dos16-handle` (`msdos-2.0-realmode-i8086`), and `dos16-fcb`
    (`msdos-1.25-heritage-i8086`), with `DOS1_FLAT_FCB_ONLY`, `DOS2_NO_DPMI32`, and
    `DOS_INCOMPATIBLE_FORK` solver guards in `engine/solver/resolve_stack.jq`.
  - Standalone `T1`/`T2` recipes for `_lib/kernel/freedos/`, `_lib/kernel/msdos/` (clean-room
    `IO.SYS` + `MSDOS.SYS`/`COMMAND.COM`), `_lib/networking/dos-pktdrv/` (`PCNTPKT` + `Watt-32`),
    `_lib/toolchains/djgpp/` (`CWSDPMI` + GNU `bash`/`coreutils`), `_lib/toolchains/kvikdos/`, and
    `_lib/toolchains/{win-cmd-asm,win-cmd-rs}/` (`WINCMD.COM`, `WINCMD1.COM`, `WINCMD.EXE`).
  - Rootless `FAT12`/`FAT16 BIGDOS`/`FAT32 LBA` disk synthesis (`dos-distro`,
    `dos-{floppy,iso,qcow2,raw,vhd,vmdk,vagrant-box}`), `wincheck --dialect dos622` batch auditing,
    and headless `kvikdos`/QEMU verification (`tests/test_dos_kernel_synthesis.{sh,cmd}`,
    `tests/test_dos_solver.{sh,cmd}`, `tests/test_qemu_msdos_smoke.{sh,cmd}`).
- **Built-in ReactOS Modular Distribution Synthesis (`synthesis/distro/reactos/`, `rapps`,
  `rosbe`)**:
  - Declarative `synthesis/schemas/execution-plan.reactos.schema.json` and 5 curated `i686` /
    `x86_64` profiles under `synthesis/profiles/reactos/`, supporting hybrid upstream ISO repacking
    (`unattend.inf` + `GuiRunOnce` `firstboot.cmd`) and full RosBE CMake/Ninja source compilation
    (`modules/optional/`).
  - Standalone `T1` `_lib/package-managers/rapps/` (guest `rapps.exe` wrapper + host `rapps-db` INI
    parser & offline prefetcher) and `_lib/toolchains/rosbe/` (`i686-w64-mingw32` and
    `x86_64-w64-mingw32` cross-toolchains), plus PowerShell-free `.cmd` fallbacks in
    `engine/common/`.
  - Strict PE header architecture enforcement (`0x014c` vs. `0x8664`, no WoW64 assumptions),
    multi-format exporters (`iso`, `raw`, `qcow2`, `vhd`, `vmdk`, `box`), `--target reactos` live
    installer media, GRUB2 -> FreeLoader multiboot co-installation, and 5-platform verification
    matrix (`tests/run_reactos_distro_matrix.{sh,cmd}`).
- **Six-Tier (`T0`–`T5`) Universal OS Synthesis & Multicloud Substrate**:
  - **`T0`: Engine, DAG Solver, Hooks & Consensus (`engine/`)**:
    - Zero-dependency stdlib (`engine/common/`), Tarjan SCC constraint solver
      (`engine/solver/resolve_stack.jq`), target triplet normalizer
      (`engine/target/triplets.{sh,cmd}`), decoupled integration hooks (`engine/hooks/`), and
      distributed lease/fencing state machines (`engine/consensus/{lock,fence}.{sh,cmd}`).
  - **`T1` & `T2`: Atomic Userland, Daemon & OS Plumbing Recipes (`_lib/`)**:
    - Codified the Standard Context Contract (`LIBSCRIPT_TARGET_SYSROOT`, `LIBSCRIPT_HOST_ROOT`,
      `LIBSCRIPT_OFFLINE`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_TARGET_ARCH`, `LIBSCRIPT_TARGET_LIBC`,
      `LIBSCRIPT_TARGET_OS`, `LIBSCRIPT_TARGET_TRIPLET`).
    - Multi-stage cross-toolchain bootstrapping (`_lib/toolchains/bootstrap/stage{0,1}.{sh,cmd}`)
      and complete base-system, kernel (`linux`, `initramfs`, `freedos`, `msdos`, `zephyr`,
      `freertos`), bootloader (`grub`, `systemd-boot`, `limine`, `refind`, `mcuboot`),
      graphics/Wayland/desktop, audio, and networking catalogs.
    - Unified `O(1)` toolchain version management (`ls-remote`, `install`, `ls`, `use`, `uninstall`)
      for Node.js, Python, Rust, Ruby, Go, Java, PHP, C/C++ compilers, and databases.
  - **`T3`: Image, OS & Artifact Synthesis (`synthesis/`)**:
    - Declarative OS configuration (`synthesis/schemas/os-config.schema.json`), execution plans
      (`synthesis/schemas/execution-plan*.schema.json`), interactive TUI configurator
      (`cli/commands/config/`), and curated profiles (`synthesis/profiles/`).
    - Isolated sysroot FHS & VFS lifecycle (`synthesis/vfs/`), GPT/MBR/LUKS2 disk provisioning
      (`synthesis/disk/`), Linux/FreeBSD/illumos/ReactOS/DOS/Bento distro builders
      (`synthesis/distro/`), offline cache/repo generators (`synthesis/repogen/`), and universal
      `package-as` drivers (`synthesis/formats/` & `synthesis/msi/`).
  - **`T4`: Infrastructure Providers, Resources & Cluster Substrates (`infrastructure/`)**:
    - Multicloud VM, resource, image-import, and Marketplace publishing
      (`infrastructure/providers/`, `infrastructure/resources/`, `infrastructure/marketplace/`),
      plus HA cluster substrates (`infrastructure/clusters/`).
  - **`T5`: Workloads, Application Stacks, Schedulers & Constellations (`workloads/`)**:
    - Declarative workload schema (`workloads/schemas/payload.schema.json`), scheduler drivers
      (`workloads/schedulers/`: `kubernetes`, `nomad`, `mesos`, `native`, `microvm`,
      `rtos_firmware`, `slurm_ray`, `tpu_vm`, `xpk`), multi-service application stacks
      (`workloads/apps/`), AI/TPU workloads (`workloads/ai/` & `workloads/payloads/ai/`), and
      stateful HA constellations (`workloads/constellations/`).
  - **`Plane A`: Cross-Cutting Node Traits (`traits/`)**:
    - Dual-mode (`T3` offline sysroot bake and `T4`/`T5` live runtime) traits across `storage`,
      `secrets`, `mesh`, `firewall`, `discovery`, `tls`, `ingress`, `logging`, `metrics`, `backup`,
      and `maintenance`.
  - **Cross-Platform Standards & Quality Invariants**:
    - Strict POSIX `/bin/sh` compliance and 100% Windows Batch (`.cmd`) parity, Option A Win32
      Hard-Fail Boundary Proforma (exit code `86`), static audits (`audit_standards`, `audit_tiers`,
      `doc_coverage`), headless QEMU boot/GUI/airgap/idempotency matrices, and strict ban on
      `git push` in automation.

### Completed Initiatives

#### Phase 12: Capability-Typed `O(1)` Version Managers, `experiments/` Plugin Engine, Multicloud Unikernel Marketplace, TPU/GCS ML Stack & RTOS Synthesis

- **Capability-Typed Manifests & `O(1)` Version Management**:
  - Extended `_lib/_common/manifest.schema.json` with `capabilities`, `adapter_only`, and
    `replaces_version_managers` across all `554` `_lib/` manifests, removing `760` dead no-op
    `service.{sh,cmd}` stubs and enforcing `EMPTY_SERVICE_STUB` in
    `devtools/audit/audit_standards.{sh,ps1}`.
  - Added zero-shim `O(1)` `${LIBSCRIPT_HOME}/bin` symlink synchronization and pruning
    (`_lib/_common/versioning.{sh,cmd}`), workspace pin walking
    (`cli/commands/resolve_env.{sh,cmd}`), and full native version-manager parity in `nodejs`
    (`.nvmrc`/`.node-version`/`corepack`), `python` (`.python-version`/`pyproject.toml`/`3.13t` PEP
    703 free-threaded), and `rust` (`rust-toolchain.toml`, `target-add`/`component-add`).
- **Open/Closed `experiments/` Plugin Architecture**:
  - Relocated the shared empirical benchmark harness and C11 `libscript_bench_probe.c` probe to
    `_lib/_common/experiment/` and added `experiments/engine.{sh,cmd}` covering `edgcpp-backends`,
    `gemma-4-sql`, `libtpu-pjrt`, `os-component-matrix`, and `win-port`.
- **UEFI Cloud-Boot Unikernels, Open edX 8-Appliance Constellation & `publish-marketplace`**:
  - Extended `package-as unikernel` with `--cloud-boot=uefi-gpt|efi-stub|azure-vhd` (hybrid GPT +
    FAT32 ESP raw disks and 1 MiB-aligned Hyper-V Gen2 `.vhd` trailers) and added
    `_lib/cloud/image-import`.
  - Added 8 single-process Open edX unikernel profiles (`profiles/openedx-unikernel/*.json`),
    `topologies/openedx-unikernel-pod/`, `schemas/marketplace-offer.schema.json`, and
    `libscript publish-marketplace` (SPDX 2.3 SBOM + AWS/Azure/GCP Marketplace bundle synthesis).
- **Cloud TPU / GKE JobSet+Kueue / 4-Role GCS ML Stack & RTOS Synthesis**:
  - Added `traits/storage/gcs_ml.{sh,cmd}` (`schemas/gcs-ml-storage.schema.json`),
    `_lib/ml-training/tpu-trainer`, `_lib/ai-serving/inference-router`,
    `payloads/schedulers/tpu_vm`, zero-cost TFRC guardrails (`schemas/tfrc-policy.schema.json`), and
    OpenAPI 3.2.0 endpoints (`/api/v1/experiments`, `/api/v1/marketplace/publish`,
    `/api/v1/components/{name}/capabilities`).
  - Added Zephyr RTOS (`_lib/kernel/zephyr`), FreeRTOS (`_lib/kernel/freertos`), MCUboot
    (`_lib/bootloaders/mcuboot`), `execution-plan.rtos.schema.json`, `package-as firmware`, and
    `payloads/schedulers/rtos_firmware`.

#### Phase 11: Multi-Node Cluster Schedulers, HA Topologies, Traits & Lifecycle Hooks

- Added Tier 4 Declarative Workload Engine (`payloads/`) and scheduler drivers (`kubernetes`,
  `nomad`, `mesos`, `slurm_ray`, `xpk`, `microvm`, `native`).
- Added Tier 3.5 High-Availability Topology Engine (`topologies/engine.{sh,cmd}`), lease locking,
  split-brain fencing, and turnkey HA blueprints (`postgres-ha`, `redis-cluster`, `valkey-cluster`,
  `openedx-ha`, `mesos-marathon-ha`, `k8s-marathon-paas`, `k0s-ha`, `minio-distributed`,
  `gke-tpu-cluster`).
- Added Unified Cross-Cutting Node Traits (`traits/`) and Dual-Layer Component Lifecycle Hooks
  (`_lib/_common/hooks.{sh,cmd}`) for physical and multi-tenant operations.

#### Phase 10: Generic 3-Mode Build Substrate & Multi-Compiler C/C++ Differential Verification

- Added universal 3-mode component provisioning and source compilation in `_lib/_common/`:
  - **Mode 1 (`--pkg-mgr=<pm>`)**: Explicit package manager selection and auto-bootstrapping across
    `apt-get`, `apk`, `dnf`, `yum`, `zypper`, `pacman`, `brew`, `port`, `pkg`, `xbps`, `emerge`,
    `winget`, `choco`, `scoop`, `nix`, `guix`, `spack`, `vcpkg`, `conan`, and `pkgx`.
  - **Mode 2 (`--from-source --toolchain=default`)**: Generic source compilation engine
    (`_lib/_common/source_builder.{sh,cmd}`) using the host's default C toolchain.
  - **Mode 3 (`--from-source --toolchain=<cc>` / `--custom-cc=<path>`)**: Compiler-namespaced source
    builds with `build-metrics.json` section and timing telemetry.
- Added standalone Tier 1 C/C++ compiler version managers
  (`_lib/languages/{gcc,clang,tcc,edgcpp,custom-cc}/`) with `cc_wrapper.{sh,cmd}`,
  `edgcpp_wrapper.{sh,cmd}`, and per-TU JSONL telemetry.
- Upgraded `_lib/databases/sqlite/` with 3-mode provisioning, C amalgamation source compilation, a
  deterministic 6-stage SQL torture suite (`test.{sh,cmd}`), and a 4-way differential compiler
  benchmark (`compare_compilers.{sh,cmd}`).
- Upgraded `_lib/kernel/linux/` and `_lib/orchestration/resolve_stack.jq` with multi-toolchain
  Kbuild support, ELF/`System.map` differential analysis (`compare_compilers.{sh,cmd}`), and 8
  declarative kernel compiler profiles in `profiles/`.

#### Phase 9: Native C11 REST API & OpenAPI 3.2.0 Control Plane

- High-performance pure C11 HTTP daemon (`c-rest-framework`) in `libscript-rest-api/`.
- Strongly typed OpenAPI 3.2.0 specification (`libscript-rest-api/openapi.yaml`).
- REST endpoints for remote component installation, stack synthesis, packaging execution,
  topologies, payloads, traits, hooks, and log streaming.
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
