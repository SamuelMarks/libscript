# Roadmap

LibScript aims to become the universal substrate for software delivery, independent of cloud vendor
or operating system.

## Phase 15: Observability Control Plane, Zero-Emulation Win32/DOS Completion & Transactional OS Updates (Next)

- [ ] Lightweight, decentralized Web Dashboard / Control Plane for real-time cluster visualization,
      constellation state inspection, and multi-node log streaming on top of `libscript-rest-api`.
- [ ] Real-time multicloud resource cost estimation and usage reporting across AWS, Azure, GCP,
      Hetzner, DigitalOcean, Linode, and Vultr.
- [ ] Complete Zero-PowerShell / Zero-`wmic` Win32 & MS-DOS (`dos32`) `engine/common/` substrate
      porting (`find_replace.cmd`, `envsubst_safe.cmd`, `uuid_gen.cmd`, `daemon_launcher.cmd`,
      `priv.cmd`, FAT16/32 fallback — documented in [WINDOWS.md](WINDOWS.md)).
- [ ] Extended Hardware-Aware Auto-Tuning: Extending `engine/common/hw_tune.{sh,cmd}` CPU/RAM/ISA
      detection to dynamically tune compiler flags (`-march`), NVMe I/O schedulers, and kernel
      sysctl profiles.
- [ ] Transactional A/B sysroot update partitions and `ostree`-style atomic rollback for immutable
      `T3` OS deployments.

---

## Completed Phases (Phases 3–14)

### Phase 14: Clean-Break `T0`–`T5` + Orthogonal Planes Architectural Refactoring (Completed)

- [x] Replaced fractional tiers (`1.5`, `3.5`) and legacy redirect shims with 6 strictly ordered
      compositional tiers (`T0` `engine/`, `T1` & `T2` atomic `_lib/` recipes, `T3` `synthesis/`,
      `T4` `infrastructure/`, `T5` `workloads/`) and 2 orthogonal planes (`Plane A` `traits/`,
      `Plane B` `experiments/` & `libscript-rest-api/`), statically enforced by
      `devtools/audit/audit_tiers.{sh,cmd}`.

### Phase 13: ReactOS Modular Distribution Synthesis, Declarative `installer-e2e` & Native Windows/MS-DOS (`dos32`) Component PMs (Completed)

- [x] Modular ReactOS (`i686` & `x86_64`) distribution synthesis (`synthesis/distro/reactos/`,
      `rapps`, `rosbe`, `synthesis/schemas/execution-plan.reactos.schema.json`,
      `synthesis/profiles/reactos/*.json`) supporting upstream ISO repacking (`unattend.inf` +
      `GuiRunOnce`), RosBE CMake/Ninja source builds, strict PE bitness guards (`0x014c` vs.
      `0x8664`), `--target reactos` quad-boot `msi-rs` live media, and 5-platform verification
      (`tests/run_reactos_distro_matrix.{sh,cmd}`).
- [x] Declarative cross-OS `installer-e2e` experiment substrate
      (`experiments/_common/pkg_ui_runner.{sh,cmd}`,
      `experiments/schemas/installer-experiment.schema.json`, `--template=installer-e2e`) and
      built-in `experiments/openedx/` Vagrant/UI verification suite.
- [x] Native Windows PE (`X64`/`X86`/`ARM64`) and MS-DOS (`dos32` + `DOS32A.EXE`) component-level
      package managers (`_lib/utilities/{jq,gawk,busybox,toybox,dash,freebsd-usr-bin}/` +
      `_lib/toolchains/openwatcom/`), target-aware `depends` dispatch (`IS_MSDOS=1`), FreeDOS/MS-DOS
      Vagrant environments (`vagrant/{freedos-1.4,msdos-1.25,msdos-2.0,msdos-4.0}/`), and
      `tests/test_win_dos_component_pm.{sh,cmd}`.

### Phase 12: Capability-Typed `O(1)` Version Managers, `experiments/` Plugin Engine, Multicloud Unikernel Marketplace & TPU/GKE/GCS ML Stack (Completed)

- [x] Capability-typed `manifest.json` contract (`userland-package`, `service-daemon`,
      `sysroot-package`, `sysroot-library`, `cross-toolchain`, `kernel-image`, `bootloader`) across
      all atomic `_lib/` components, removing `760` dead `service.{sh,cmd}` stubs and enforcing
      `EMPTY_SERVICE_STUB` in `devtools/audit/audit_standards.{sh,ps1}`.
- [x] Zero-shim `O(1)` `${LIBSCRIPT_HOME}/bin` symlink farm (`engine/common/versioning.{sh,cmd}`),
      `.libscript-version` workspace pin resolution (`libscript resolve-env`), and native
      replacement upgrades for `nodejs` (`.nvmrc`/`.node-version`/`corepack`), `python`
      (`.python-version`/`pyproject.toml`/`3.13t` free-threaded), and `rust` (`rust-toolchain.toml`,
      `target-add`/`component-add`).
- [x] Open/Closed top-level `experiments/<suite-id>/` plugin engine (`experiments/engine.{sh,cmd}`)
      and shared `experiments/_common/` C11/POSIX/Batch benchmark substrate covering
      `edgcpp-backends`, `gemma-4-sql`, `libtpu-pjrt`, `openedx`, `os-component-matrix`, and
      `win-port`.
- [x] UEFI/GPT (`--cloud-boot=uefi-gpt|efi-stub`) and 1 MiB-aligned Hyper-V Gen2 VHD
      (`--cloud-boot=azure-vhd`) unikernel disk image synthesis,
      `infrastructure/resources/image-import`, the 8-appliance Open edX unikernel constellation
      (`synthesis/profiles/unikernel/openedx/*.json` +
      `workloads/constellations/openedx-unikernel-pod/`), and SPDX 2.3 compliance-gated
      AWS/Azure/GCP Marketplace publishing (`libscript publish-marketplace`).
- [x] 4-role regional GCS ML storage trait (`traits/storage/gcs_ml.{sh,cmd}`,
      `engine/schemas/gcs-ml-storage.schema.json`), `workloads/ai/tpu-trainer`,
      `workloads/ai/inference-router`, `workloads/schedulers/tpu_vm.{sh,cmd}`, zero-cost TFRC
      guardrails (`engine/schemas/tfrc-policy.schema.json`), and OpenAPI 3.2.0 endpoints
      (`/v1/recipes`, `/v1/synthesis`, `/v1/infrastructure`, `/v1/workloads`, `/v1/traits`,
      `/v1/experiments`).

### Phase 11: Multi-Node Cluster Schedulers, HA Constellations, Traits & Lifecycle Hooks (Completed)

- [x] `T5` Declarative Workload Engine (`workloads/`) and pluggable scheduler drivers for
      **Kubernetes** (`kubectl`, `k8s-marathon-paas`, `kubernetes-k0s`, `kubernetes-thw`), **Apache
      Mesos & Marathon** (`mesos`, `marathon`), **HashiCorp Nomad** (`nomad`), **Slurm/Ray**
      (`slurm_ray`), **Google Cloud XPK / TPU VM** (`xpk`, `tpu_vm`), **MicroVMs/Unikernels & RTOS**
      (`microvm`, `rtos_firmware`), and **8+ Native OS Init Systems** (`native`).
- [x] `T4` Cluster Substrate & `T5` Stateful Constellation Engines
      (`infrastructure/clusters/engine.{sh,cmd}`, `workloads/constellations/engine.{sh,cmd}`),
      distributed lease locking (`engine/consensus/lock.{sh,cmd}`), and automated split-brain
      fencing (`engine/consensus/fence.{sh,cmd}`).
- [x] Turnkey HA blueprints for `postgres-ha`, `redis-cluster`, `valkey-cluster`, `openedx-ha`,
      `mesos-marathon-ha`, `k8s-marathon-paas`, `k0s-ha`, `minio-distributed`, and
      `gke-tpu-cluster`.
- [x] Unified Cross-Cutting Node Traits (`traits/engine.{sh,cmd}`): `storage`, `secrets`
      (zero-env-leak FIFO injection), `mesh` (WireGuard/Tailscale), `firewall` (anti-lockout
      `nftables`/`iptables`/`pf`/`netsh`), `discovery` (Cloud DNS + `/etc/hosts`), `tls`, `ingress`,
      `logging`, `metrics`, `backup` (ZFS/Btrfs CoW snapshots + S3/GCS/Azure/Restic shipping), and
      `maintenance`.
- [x] Dual-Layer Component Lifecycle Hooks (`engine/common/hooks.{sh,cmd}`): physical hooks
      (`configure`, `probe`, `announce`, `log_stream`, `metrics`, `backup`, `restore`, `upgrade`,
      `rollback`, `maintenance`) and logical multi-tenant hooks (`provision_tenant`,
      `deprovision_tenant`, `backup_tenant`, `restore_tenant`).

### Phase 10: Generic 3-Mode Build Substrate & Multi-Compiler C/C++ Differential Verification (Completed)

- [x] Universal 3-mode build/install substrate (`engine/common/source_builder.{sh,cmd}`,
      `pkg_mgr.{sh,cmd}`, `component_core.{sh,cmd}`) supporting `--pkg-mgr=<pm>`,
      `--from-source --toolchain=default`, and
      `--from-source --toolchain=gcc|clang|tcc|edgcpp|custom-cc`.
- [x] Standalone `T1` C/C++ compiler recipes (`_lib/languages/{gcc,clang,tcc,edgcpp,custom-cc}/`)
      and unified `cc` / `c` / `cpp` routers with `cc_wrapper.{sh,cmd}` and
      `edgcpp_wrapper.{sh,cmd}` JSONL telemetry.
- [x] EDG C/C++ Compiler Frontend (`edgcpp` v7.0.1) multi-flavor installer (`edgcpp+llvm+gcc`,
      `edgcpp+llvm`, `edgcpp+gcc`) and 13-target C11/C++17 corpus verification
      (`tests/test_edgcpp_corpus_matrix.{sh,cmd}`).
- [x] SQLite C amalgamation multi-compiler builder, 6-stage SQL torture suite, and 4-way
      differential benchmark (`_lib/databases/sqlite/compare_compilers.{sh,cmd}`).
- [x] Linux kernel multi-toolchain Kbuild engine, ELF/`System.map` ABI differential harness
      (`_lib/kernel/linux/compare_compilers.{sh,cmd}`), and declarative kernel compiler profiles.

### Phase 9: Native C11 REST API & OpenAPI 3.2.0 Control Plane (Completed)

- [x] High-performance pure C11 HTTP daemon (`c-rest-framework`) in `libscript-rest-api/`.
- [x] Strongly typed OpenAPI 3.2.0 specification (`libscript-rest-api/openapi.yaml`).
- [x] REST endpoints for component lifecycle, stack synthesis, artifact packaging, topologies,
      payloads, traits, hooks, and job status polling.
- [x] Native CMake build system, architecture guide, and daemon integration scripts.

### Phase 8: Universal Live-CD / Live-USB Multiboot Installer (`msi-rs`) (Completed)

- [x] Specification and execution schema (`synthesis/schemas/execution-plan.live.schema.json`).
- [x] Live installer image builder (`devtools/build_live_installer.sh` / `.cmd`).
- [x] Tri-modal operator interface: Headless unattended (`msiexec`), curses TUI, and kiosk GUI
      (`msi-gui` on Wayland `cage` / X11 `openbox`).
- [x] Multiboot co-installation across Linux, FreeBSD, illumos, and ReactOS on a single machine with
      automated bootloader chaining.
- [x] Automated visual screenshot capture harness (`devtools/capture_msi_live_screenshots.sh` /
      `.cmd`).
- [x] Air-gapped offline payload baking and USB physical drive writer (`devtools/write_usb.sh` /
      `.cmd`).
- [x] Engineering specification and checklist tracked in
      [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).

### Phase 7: Illumos-Based Modular Distribution & Verification Matrix (Completed)

- [x] Specification & schema (`synthesis/schemas/execution-plan.illumos.schema.json`) with modular
      profiles (`minimal-server`, `zfs-cloud`, `desktop-mate-x11`, `desktop-xfce-x11`,
      `cde-retro-x11`, `hardened-runit`, `pkgsrc-developer`).
- [x] Pluggable Init Systems (`smf`, `runit`, `s6`, `dinit`, `inittab-sysv`).
- [x] Display & Desktop modular staging (X11 Xorg, MATE, XFCE4, CDE, LightDM, SLiM, XDM, Boomer
      kernel audio).
- [x] Canonical ZFS root pool (`rpool`) dataset layout and `/etc/vfstab` integration.
- [x] Multi-format disk image export (Raw GPT/VTOC, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- [x] Headless boot milestone smoketests, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency
      test harness.
- [x] Vagrant-only multi-platform verification matrix across
      `{macOS, Windows, FreeBSD, SunOS, Linux}`.

### Phase 6: FreeBSD-Based Modular Distribution & Verification Matrix (Completed)

- [x] Specification & schema (`synthesis/schemas/execution-plan.freebsd.schema.json`) with modular
      profiles.
- [x] Pluggable Init Systems (`bsd-rc`, `openrc`, `runit`, `s6`, `dinit`).
- [x] Display & Desktop modular staging (Wayland, X11, Sway, XFCE4, Plasma 6, seatd, PipeWire).
- [x] Multi-format disk image export (Raw GPT, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- [x] Headless boot, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency test harness.
- [x] Vagrant-only multi-platform verification matrix across
      `{macOS, Windows, FreeBSD, SunOS, Linux}`.

### Phase 5: Hardware Acceleration & AI Infrastructure (Completed)

- [x] Abstracted provisioning for TPU and GPU Virtual Machines (`workloads/payloads/ai/gcp-tpu-vm/`,
      `gcp-gpu-vm/`).
- [x] GKE integration for distributed AI workloads via XPK
      (`workloads/payloads/ai/gke-xpk-training/`, `gke-xpk-inference/`,
      `infrastructure/clusters/gke-tpu-cluster/`).
- [x] Automation for inference engines (`vLLM`, `JetStream`, `Ollama`).
- [x] Real-Time Operating System (RTOS) & MCU Firmware Synthesis (`_lib/kernel/zephyr/`,
      `_lib/kernel/freertos/`, `_lib/bootloaders/mcuboot/`,
      `synthesis/formats/firmware_bin.{sh,cmd}`, `workloads/constellations/iot-mqtt-edge-pod/`, and
      `workloads/schedulers/rtos_firmware.{sh,cmd}`).
- [x] Bare-metal generic GPU passthrough setup for local development.

### Phase 4: Terminal UI & Structured Telemetry (Completed)

- [x] Terminal User Interface (TUI) for OS synthesis (`libscript config os`) and stack packaging via
      `package-as tui`.
- [x] Integrated log aggregation, health probing, and structured metrics via `traits/logging/`,
      `traits/metrics/`, and component `hooks/{probe,log_stream,metrics}`.

### Phase 3: Advanced PaaS & Cluster Mesh (Completed)

- [x] High-availability cluster orchestration blueprints (Master/Slave election, Raft-based state,
      Cross-cloud mesh: `postgres-ha`, `redis-cluster`, `valkey-cluster`, `openedx-ha`,
      `mesos-marathon-ha`, `k8s-marathon-paas`, `k0s-ha`, `minio-distributed`).
- [x] Automated global load balancer and reverse proxy configuration (`traits/ingress/`, `netctl`).
- [x] Provider Expansion: Added DigitalOcean, Linode, Vultr, Hetzner, OCI, OVH, and Proxmox VE to
      the multicloud wrapper (`infrastructure/providers/`).
- [x] Unified Deployment Grammar: High-level declarative DSLs
      (`workloads/schemas/payload.schema.json` and
      `workloads/constellations/constellation.schema.json`) to describe globally distributed stacks
      and clusters.
- [x] Encrypted cross-node mesh networking / Zero-Trust Sidecars (`traits/mesh/` WireGuard &
      Tailscale overlays).
- [x] Git-driven deployment workflows (`libscript deploy`).
- [x] Cross-cloud persistent volume and state management (`traits/storage/`, `traits/backup/`).

_For earlier completed phases (Phases 1 and 2) and detailed release notes, see
[CHANGELOG.md](CHANGELOG.md)._
