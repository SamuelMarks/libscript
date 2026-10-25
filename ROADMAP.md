# Roadmap

LibScript aims to become the universal substrate for software delivery, independent of cloud vendor
or operating system.

## Phase 3: Advanced PaaS & Cluster Mesh (Current)

- [x] High-availability cluster orchestration blueprints (Master/Slave election, Raft-based state,
      Cross-cloud mesh: `postgres-ha`, `redis-cluster`, `valkey-cluster`, `mesos-marathon-ha`,
      `k8s-marathon-paas`, `k0s-ha`, `minio-distributed`).
- [x] Automated global load balancer and reverse proxy configuration (`traits/ingress/`, `netctl`).
- [x] Provider Expansion: Add support for DigitalOcean, Linode, and Vultr to the multicloud wrapper.
- [x] Unified Deployment Grammar: High-level declarative DSLs (`payloads/payload.schema.json` and
      `topologies/topology.schema.json`) to describe globally distributed stacks and clusters.
- [x] Encrypted cross-node mesh networking / Zero-Trust Sidecars (`traits/mesh/` WireGuard &
      Tailscale overlays).
- [x] Git-driven deployment workflows (`libscript deploy`).
- [x] Cross-cloud persistent volume and state management (`traits/storage/`, `traits/backup/`).

## Phase 4: Hardware & Observability (Next)

- [x] Hardware-Aware Optimization: Automatically tuning component installations based on detected
      hardware (CPU instructions, NVMe presence).
- [x] Terminal User Interface (TUI) for stack and PaaS management via `package-as TUI`.
- [x] Lightweight, decentralized Web Dashboard / Control Plane for real-time monitoring and resource
      management.
- [x] Integrated log aggregation and health monitoring.
- [x] Real-time multicloud resource cost and usage reporting.

## Phase 5: Hardware Acceleration & AI Infrastructure (Current)

- [x] Abstracted provisioning for TPU and GPU Virtual Machines.
- [x] GKE integration for distributed AI workloads via XPK.
- [x] Automation for inference engines (vLLM, JetStream).
- [x] Bare-metal generic GPU passthrough setup for local development.

## Phase 6: FreeBSD-Based Modular Distribution & Verification Matrix

- [x] Specification & schema (`execution-plan.freebsd.schema.json`) with modular profiles.
- [x] Pluggable Init Systems (`bsd-rc`, `openrc`, `runit`, `s6`, `dinit`).
- [x] Display & Desktop modular staging (Wayland, X11, Sway, XFCE4, Plasma 6, seatd, PipeWire).
- [x] Multi-format disk image export (Raw GPT, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- [x] Headless boot, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency test harness.
- [x] Vagrant-only multi-platform verification matrix across
      `{macOS, Windows, FreeBSD, SunOS, Linux}`.

## Phase 7: Illumos-Based Modular Distribution & Verification Matrix

- [x] Specification & schema (`execution-plan.illumos.schema.json`) with modular profiles
      (`minimal-server`, `zfs-cloud`, `desktop-mate-x11`, `desktop-xfce-x11`, `cde-retro-x11`,
      `hardened-runit`, `pkgsrc-developer`).
- [x] Pluggable Init Systems (`smf`, `runit`, `s6`, `dinit`, `inittab-sysv`).
- [x] Display & Desktop modular staging (X11 Xorg, MATE, XFCE4, CDE, LightDM, SLiM, XDM, Boomer
      kernel audio).
- [x] Canonical ZFS root pool (`rpool`) dataset layout and `/etc/vfstab` integration.
- [x] Multi-format disk image export (Raw GPT/VTOC, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- [x] Headless boot milestone smoketests, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency
      test harness.
- [x] Vagrant-only multi-platform verification matrix across
      `{macOS, Windows, FreeBSD, SunOS, Linux}`.

## Phase 8: Universal Live-CD / Live-USB Multiboot Installer (`msi-rs`)

- [x] Specification and execution schema (`execution-plan.live.schema.json`).
- [x] Live installer image builder (`devtools/build_live_installer.sh` / `.cmd`).
- [x] Tri-modal operator interface: Headless unattended (`msiexec`), curses TUI, and kiosk GUI
      (`msi-gui` on Wayland `cage` / X11 `openbox`).
- [x] Multiboot co-installation across Linux, FreeBSD, and illumos on a single machine with
      automated bootloader chaining.
- [x] Automated visual screenshot capture harness (`devtools/capture_msi_live_screenshots.sh` /
      `.cmd`).
- [x] Air-gapped offline payload baking and USB physical drive writer (`devtools/write_usb.sh` /
      `.cmd`).
- [x] Engineering specification and checklist tracked in
      [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).

## Phase 9: Native REST API & OpenAPI 3.0 Control Plane

- [x] High-performance C++ HTTP daemon in `libscript-rest-api/`.
- [x] Strongly typed OpenAPI 3.0 specification (`libscript-rest-api/openapi.yaml`).
- [x] REST endpoints for component lifecycle, stack synthesis, artifact packaging, and job status
      polling.
- [x] Native CMake build system, architecture guide, and daemon integration scripts.

## Phase 10: Generic 3-Mode Build Substrate & 4-Way C Compiler Differential Verification

- [x] Universal 3-mode build/install substrate (`_lib/_common/source_builder.{sh,cmd}`,
      `pkg_mgr.{sh,cmd}`, `component_core.{sh,cmd}`) supporting `--pkg-mgr=<pm>`,
      `--from-source --toolchain=default`, and
      `--from-source --toolchain=gcc|clang|tcc|edgcpp|custom-cc`.
- [x] Standalone Tier 1 C/C++ compiler recipes (`_lib/languages/{gcc,clang,tcc,edgcpp,custom-cc}/`)
      and unified `cc` / `c` / `cpp` routers with `cc_wrapper.{sh,cmd}` and
      `edgcpp_wrapper.{sh,cmd}` JSONL telemetry.
- [x] EDG C/C++ Compiler Frontend (`edgcpp` v7.0.1) multi-flavor installer (`edgcpp+llvm+gcc`,
      `edgcpp+llvm`, `edgcpp+gcc`) and 13-target C11/C++17 corpus verification
      (`tests/test_edgcpp_corpus_matrix.{sh,cmd}`).
- [x] SQLite C amalgamation multi-compiler builder, 6-stage SQL torture suite, and 4-way
      differential benchmark (`_lib/databases/sqlite/compare_compilers.{sh,cmd}`).
- [x] Linux kernel multi-toolchain Kbuild engine, ELF/`System.map` ABI differential harness
      (`_lib/kernel/linux/compare_compilers.{sh,cmd}`), and declarative kernel compiler profiles.

## Phase 11: Multi-Node Cluster Schedulers, HA Topologies, Traits & Lifecycle Hooks

- [x] Tier 4 Declarative Workload Engine (`payloads/`) and pluggable scheduler drivers for
      **Kubernetes** (`kubernetes`, `k8s-marathon`, `kubernetes-k0s`, `kubernetes-thw`), **Apache
      Mesos & Marathon** (`mesos`, `marathon`), **HashiCorp Nomad** (`nomad`), **Slurm/Ray**
      (`slurm_ray`), **Google Cloud XPK** (`xpk`), **MicroVMs/Unikernels** (`microvm`), and **8+
      Native OS Init Systems** (`native`).
- [x] Tier 3.5 High-Availability Topology Engine (`topologies/engine.{sh,cmd}`), distributed lease
      locking (`topologies/lock.{sh,cmd}`), and automated split-brain fencing
      (`topologies/fence.{sh,cmd}`).
- [x] Turnkey HA blueprints for `postgres-ha`, `redis-cluster`, `valkey-cluster`,
      `mesos-marathon-ha`, `k8s-marathon-paas`, `k0s-ha`, `minio-distributed`, and
      `gke-tpu-cluster`.
- [x] Unified Cross-Cutting Node Traits (`traits/engine.{sh,cmd}`): `storage`, `secrets`
      (zero-env-leak FIFO injection), `mesh` (WireGuard/Tailscale), `firewall` (anti-lockout
      `nftables`/`iptables`/`pf`/`netsh`), `discovery` (Cloud DNS + `/etc/hosts`), `tls`, `ingress`,
      `logging`, `metrics`, `backup` (ZFS/Btrfs CoW snapshots + S3/GCS/Azure/Restic shipping), and
      `maintenance`.
- [x] Dual-Layer Component Lifecycle Hooks (`_lib/_common/hooks.{sh,cmd}`): physical hooks
      (`configure`, `probe`, `announce`, `log_stream`, `metrics`, `backup`, `restore`, `upgrade`,
      `rollback`, `maintenance`) and logical multi-tenant hooks (`provision_tenant`,
      `deprovision_tenant`, `backup_tenant`, `restore_tenant`).

_For completed phases (Phase 1 and 2), please see the [CHANGELOG.md](CHANGELOG.md)._
