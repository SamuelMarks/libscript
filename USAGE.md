# Usage Guide

LibScript provides a unified, cross-platform interface for software provisioning, toolchain version
management, operating system synthesis, and multicloud AI cluster orchestration. All commands
maintain strict functional parity across `./libscript.sh` (POSIX `/bin/sh`) and `libscript.cmd`
(Windows Batch).

---

## 1. Native Toolchain Version Management (Tier 1)

LibScript natively replaces external version managers like `nvm`, `fnm`, `pyenv`, `rustup`, `rvm`,
and `sdkman`. It provides five universal lifecycle operations across all 160+ supported runtimes and
databases.

### The Universal Lifecycle Verbs

```sh
# 1. Query available versions from official upstream sources
./libscript.sh ls-remote nodejs
./libscript.sh ls-remote python
./libscript.sh ls-remote rust
./libscript.sh ls-remote postgres

# 2. Install specific versions side-by-side into ~/.libscript/<tool>/<version>/
./libscript.sh install nodejs 22.14.0
./libscript.sh install python 3.12.3
./libscript.sh install rust 1.85.0
./libscript.sh install postgres 16.2

# 3. List locally installed versions
./libscript.sh ls nodejs
./libscript.sh ls python

# 4. Activate a specific version in the active shell (prepends isolated bin/ to PATH)
./libscript.sh use nodejs 22.14.0
./libscript.sh use python 3.12.3

# 5. Cleanly uninstall a version
./libscript.sh uninstall nodejs 20.0.0
```

### Direct Component CLI Execution

Every component in `_lib/` is an autonomous package manager and can be invoked directly:

```sh
# POSIX
./_lib/languages/nodejs/cli.sh ls-remote
./_lib/languages/python/cli.sh install 3.12
./_lib/languages/python/cli.sh use 3.12
./_lib/databases/postgres/cli.sh install 16
./_lib/databases/postgres/cli.sh start

# Windows Batch
_lib\languages\python\cli.cmd install 3.12
_lib\databases\postgres\cli.cmd start
```

### Installation Method Resolution Chain & Generic 3-Mode Build Substrate

When requesting a component, LibScript supports three universal installation and source-compilation
modes in addition to version manager fallbacks:

1. **`libscript_native`** (Default: isolated binary download or compilation into
   `${LIBSCRIPT_HOME}`)
2. **`from-source`** (Compiles from verified source archive using `--toolchain=default` or a custom
   C toolchain: `gcc`, `clang`, `tcc`, `custom-cc`, or `--custom-cc=/path/to/cc`)
3. **`system` / `--pkg-mgr=<pm>`** (Explicitly targets any OS or ecosystem package manager:
   `apt-get`, `apk`, `dnf`, `brew`, `winget`, `choco`, `scoop`, `nix`, `spack`, `vcpkg`, `pkgx`,
   auto-bootstrapping `_lib/package-managers/<pm>` if not yet installed)
4. **`mise` / `asdf` / `pkgx` / `vfox`** (Third-party version manager delegation)

Override globally or per component via CLI flags or environment variables:

```sh
# Mode 1: Install via a specific package manager
./libscript.sh install sqlite latest --pkg-mgr=brew
./libscript.sh install sqlite latest --pkg-mgr=apt-get

# Mode 2: Build from source with the default platform C toolchain
./libscript.sh install sqlite 3.46.1 --from-source --toolchain=default

# Mode 3: Build from source with a custom C toolchain (gcc, clang, tcc, custom-cc)
./libscript.sh install sqlite 3.46.1 --from-source --toolchain=custom-cc
./libscript.sh install sqlite 3.46.1 --custom-cc=/path/to/my-c-compiler

# Run 4-way differential C compiler verification (SQLite amalgamation & Linux kernel)
./_lib/databases/sqlite/compare_compilers.sh
./_lib/kernel/linux/compare_compilers.sh
```

### Inspecting Component Environment (`info` & `env`)

```sh
# View installation paths, status, and ports
./libscript.sh info postgres 16

# Export environment variables in standard formats (json, docker, cmd, powershell)
FORMAT=json ./libscript.sh env postgres 16
```

---

## 2. Declarative OS Configuration & TUI Engine (Tier 2)

LibScript can synthesize customized, bootable operating system images from declarative
specifications conforming to `os-config.schema.json`.

### Interactive Terminal Configurator (`libscript config os`)

Launch an interactive terminal menu (matching Linux kernel `menuconfig` via ANSI VT100 / whiptail /
dialog):

```sh
# POSIX
./libscript.sh config os

# Windows Batch
libscript.cmd config os
```

### Working with Curated Profiles

Pre-configured profiles are available in `profiles/`:

```sh
# Load a curated profile in the configurator
./libscript.sh config os --profile=linux-desktop-sway-wayland

# Validate an existing configuration against os-config.schema.json
./libscript.sh config os --validate=my-os.json

# Export the active configuration to a portable JSON file
./libscript.sh config os --profile=linux-standard-server-glibc --export=server.json
```

Available curated profiles include:

- **Minimal & Enterprise Servers**: `linux-minimal-headless-musl.json`,
  `linux-standard-server-glibc.json`, `freebsd-server-standard.json`
- **Modern Desktops & Compositors**: `linux-desktop-sway-wayland.json`,
  `linux-desktop-hyprland.json`, `linux-desktop-kde-plasma.json`, `linux-desktop-xfce-x11.json`,
  `freebsd-desktop-xfce.json`
- **Linux From Scratch (LFS) Workstations**: `lfs-minimal-headless.json`,
  `lfs-openrc-wayland-sway.json`, `lfs-runit-wayland-hyprland.json`, `lfs-s6-wayland-labwc.json`,
  `lfs-systemd-wayland-plasma6.json`, `lfs-systemd-wayland-gnome.json`,
  `lfs-sysvinit-x11-openbox.json`, `lfs-dinit-musl-minimal.json`
- **Distribution-Style Stacks**: `linux-alpine-style-minimal.json`,
  `linux-alpine-style-standard.json`, `linux-debian-style-minimal.json`,
  `linux-debian-style-server.json`, `linux-redhat-style-minimal.json`,
  `linux-redhat-style-server.json`
- **illumos & SunOS Syntheses (`profiles/illumos/`)**: `minimal-server.json`, `cde-retro-x11.json`,
  `desktop-mate-x11.json`, `desktop-xfce-x11.json`, `hardened-runit.json`, `pkgsrc-developer.json`,
  `zfs-cloud.json`
- **Cloud & MicroVM Appliances**: `cloud-aws-ami-base.json`, `cloud-azure-vhd-base.json`,
  `cloud-gcp-gce-base.json`, `hypervisor-vmware-esxi.json`, `hypervisor-proxmox-template.json`,
  `firecracker-microvm-appliance.json`, `unikraft-nginx-redis.json`, `osv-cloud-runtime.json`
- **Multi-Compiler Linux Kernel Profiles**: `linux-kernel-gcc-tiny.json`,
  `linux-kernel-clang-tiny.json`, `linux-kernel-tcc-tiny.json`, `linux-kernel-custom-cc-tiny.json`,
  `linux-kernel-gcc-defconfig.json`, `linux-kernel-custom-cc-defconfig.json`

---

## 3. Universal Artifact Packaging (`package-as`)

The `package-as` engine transforms your local stack, container root, or synthesized OS configuration
into deployable media:

### Operating System & Virtualization Formats

```sh
# 1. Raw flashable disk image for bare-metal drives (dd if=... of=/dev/sdX)
./libscript.sh package-as raw-img

# 2. Virtual machine and hypervisor disk images (compressed)
./libscript.sh package-as qcow2            # QEMU / KVM / Proxmox VE
./libscript.sh package-as vmdk             # VMware ESXi / Workstation
./libscript.sh package-as vdi              # VirtualBox
./libscript.sh package-as vagrant-box       # Vagrant .box archive (QEMU / Libvirt / VirtualBox)
./libscript.sh package-as hyperv-vhd       # Microsoft Hyper-V (VHD/VHDX)
./libscript.sh package-as proxmox-template # Proxmox VE template

# 3. Direct cloud image synthesis
./libscript.sh package-as aws-ami          # Amazon AWS AMI
./libscript.sh package-as azure-vhd        # Microsoft Azure VHD
./libscript.sh package-as gcp-image        # Google Cloud Platform image

# 4. Hybrid live bootable ISO (UEFI + BIOS) with SquashFS and OverlayFS
./libscript.sh package-as iso

# 5. Bootable FreeBSD and illumos images with UFS or ZFS pools
./libscript.sh package-as bsd-img          # FreeBSD UFS/ZFS image
./libscript.sh package-as illumos-distro   # illumos / SunOS ZFS root pool image

# 6. Direct-kernel boot image for microVMs (Firecracker / Cloud-Hypervisor)
./libscript.sh package-as unikernel

# 7. Clean rootfs archives for OCI containers, LXC, or FreeBSD Jails
./libscript.sh package-as rootfs-tar
./libscript.sh package-as docker
```

### Native Application Installers

```sh
# Windows Installers
./libscript.sh package-as msi              # Windows Installer (WiX / msi-rs)
./libscript.sh package-as innosetup        # Inno Setup (.exe)
./libscript.sh package-as nsis             # NSIS (.exe)

# macOS Packages
./libscript.sh package-as pkg              # Flat installer package
./libscript.sh package-as dmg              # Disk image

# Linux & BSD Packages
./libscript.sh package-as deb              # Debian / Ubuntu
./libscript.sh package-as rpm              # Fedora / RHEL / CentOS
./libscript.sh package-as apk              # Alpine Linux
./libscript.sh package-as txz              # FreeBSD package tarball

# Interactive Terminal Installer
./libscript.sh package-as tui
```

---

## 4. Universal Live-CD / Live-USB Multiboot Installer

LibScript provides an automated engine for building turn-key live bootable installer ISOs powered by
`msi-rs`:

```sh
# 1. Build a live hybrid installer ISO from an execution plan schema
./devtools/build_live_installer.sh execution-plan.live.schema.json build/live-installer.iso

# 2. Write the bootable installer image directly to physical USB media
./devtools/write_usb.sh build/live-installer.iso /dev/sdX

# 3. Capture automated visual verification screenshots across installer stages
./devtools/capture_msi_live_screenshots.sh build/live-installer.iso
```

For mode options (Headless, TUI, kiosk GUI) and multi-OS co-installation details, consult
[LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).

---

## 5. Declarative Stacks & Ingress (`libscript.json`)

Define multi-tier services, databases, and ingress in a `libscript.json` file:

```json
{
  "name": "enterprise-app",
  "domain": "app.example.com",
  "dependencies": {
    "toolchains": [{ "name": "python", "version": "3.12" }],
    "databases": [{ "name": "postgres", "version": "16" }],
    "servers": [{ "name": "nginx", "ports": [80, 443] }]
  },
  "services": [
    {
      "name": "backend",
      "command": "uvicorn main:app --port 8000",
      "env": { "PORT": "8000" }
    }
  ],
  "ingress": {
    "tls": "letsencrypt",
    "routes": [
      { "path": "/api/", "proxy_pass": "http://127.0.0.1:8000/" },
      { "path": "/", "root": "./web/dist", "try_files": "$uri $uri/ /index.html" }
    ]
  }
}
```

### Lifecycle Execution

```sh
# Resolve dependencies across tiers and stage components
./libscript.sh install-deps

# Daemonize services (systemd/launchd), configure netctl reverse proxy, and start daemons
./libscript.sh start

# Check running daemon status
./libscript.sh status all

# Stop all background services
./libscript.sh stop all
```

---

## 6. Multicloud & AI Cluster Deployment (Tier 3)

Deploy stacks and custom synthesized OS images across public clouds, hypervisors, and AI hardware.

### High-Level Provisioning & Teardown

```sh
# Provision a stack on AWS: <provider> <node_name> <vpc/network> <region> <local_path> <remote_path>
./libscript.sh provision aws prod-node vpc-main us-east-1 ./ ~/app

# Provision on Azure
./libscript.sh provision azure prod-node rg-east eastus ./ ~/app

# Provision on GCP
./libscript.sh provision gcp prod-node project-main us-central1-a ./ ~/app

# Clean teardown of provisioned compute, NICs, and firewalls
./libscript.sh deprovision aws prod-node vpc-main us-east-1
```

### Hardware-Accelerated AI & TPU Workloads

```sh
# Provision a Google Cloud TPU VM or GPU VM with GCS FUSE and TensorBoard telemetry
./payloads/ai/gcp-tpu-vm/deploy.sh
./payloads/ai/gcp-gpu-vm/deploy.sh

# Launch distributed training or serving across TPU Pod slices via GKE and XPK
./libscript.sh payload submit payloads/ai/gke-xpk-training/payload.json --scheduler xpk
./libscript.sh payload submit payloads/ai/gke-xpk-inference/payload.json --scheduler xpk
./libscript.sh payload submit payloads/ai/vllm/payload.json --scheduler kubernetes
```

### Reverse Proxy & Ingress Management (`netctl`)

Use the standalone `netctl` routing abstraction to emit configurations directly:

```sh
# Emit an Nginx reverse proxy configuration with upstream SSL termination
./netctl.sh --listen 80 --listen 443 --proxy /api http://localhost:8000 --static / /var/www --emit nginx

# Emit an Apache virtualhost configuration
./netctl.sh --listen 80 --proxy / http://localhost:3000 --emit apache
```

### Programmatic Orchestration via REST API (`libscript-rest-api`)

Build and launch the lightweight C++ daemon to orchestrate LibScript over HTTP:

```sh
# Build and run the REST API daemon
cd libscript-rest-api && mkdir -p build && cd build
cmake .. && cmake --build .
./libscript_api_server --port 8080

# Query API health or submit a component install
curl http://localhost:8080/health
curl -X POST http://localhost:8080/api/v1/install -H "Content-Type: application/json" -d '{"component":"nodejs","version":"22.14.0"}'
```

---

## 7. Multi-Node Cluster Schedulers & Declarative Payloads (Tier 4)

Compile and submit declarative workloads (`payloads/payload.schema.json`)—including stateless web
APIs, stateful services, distributed ML training, search-engine reindexing, and unikernels—to
**Kubernetes**, **Apache Mesos / Marathon**, **HashiCorp Nomad**, **Slurm / Ray**, **Google XPK**,
**MicroVMs**, or **8+ Native OS Init Supervisors**:

```sh
# Compile a workload definition into a target scheduler manifest (YAML/JSON/HCL/systemd)
./libscript.sh payload compile payloads/web/stateless-api/payload.json --scheduler kubernetes
./libscript.sh payload compile payloads/web/stateless-api/payload.json --scheduler mesos
./libscript.sh payload compile payloads/web/stateless-api/payload.json --scheduler nomad

# Submit workloads across multi-node schedulers
./libscript.sh payload submit payloads/web/stateless-api/payload.json --scheduler kubernetes
./libscript.sh payload submit payloads/web/stateless-api/payload.json --scheduler mesos
./libscript.sh payload submit payloads/web/stateless-api/payload.json --scheduler nomad
./libscript.sh payload submit payloads/batch/etl-worker/payload.json --scheduler nomad
./libscript.sh payload submit payloads/unikernel/osv-microservice/payload.json --scheduler microvm

# Inspect workload status, tail logs, or stop/destroy deployments
./libscript.sh payload status stateless-api --scheduler kubernetes
./libscript.sh payload logs stateless-api --scheduler nomad
./libscript.sh payload stop stateless-api --scheduler mesos
./libscript.sh payload destroy stateless-api --scheduler kubernetes
```

---

## 8. High-Availability (HA) Topologies & Consensus Choreography (Tier 3.5)

Orchestrate multi-node stateful clusters with distributed lease locking, WireGuard mesh overlays,
and automated split-brain fencing (`topologies/`):

```sh
# Bootstrap multi-node High-Availability clusters
./libscript.sh topology up topologies/postgres-ha/topology.json
./libscript.sh topology up topologies/redis-cluster/topology.json
./libscript.sh topology up topologies/valkey-cluster/topology.json
./libscript.sh topology up topologies/mesos-marathon-ha/topology.json
./libscript.sh topology up topologies/k8s-marathon-paas/topology.json
./libscript.sh topology up topologies/k0s-ha/topology.json
./libscript.sh topology up topologies/minio-distributed/topology.json

# Inspect cluster quorum and node state (.topology_state.json)
./libscript.sh topology status topologies/postgres-ha/topology.json

# Scale worker/replica pools, drain nodes, or trigger fenced leader failover
./libscript.sh topology scale topologies/postgres-ha/topology.json pg-replicas=4
./libscript.sh topology drain topologies/postgres-ha/topology.json pg-replicas-2
./libscript.sh topology failover topologies/postgres-ha/topology.json pg-replicas-1

# Perform a zero-downtime rolling upgrade across the topology
./libscript.sh topology upgrade topologies/postgres-ha/topology.json 16.4

# Destroy topology and release cloud resources
./libscript.sh topology destroy topologies/postgres-ha/topology.json
```

---

## 9. Unified Cross-Cutting Node Traits & Lifecycle Hooks

### Unified Traits (`traits/`)

Apply composable host and sysroot capabilities in deterministic priority order (`storage` ->
`secrets` -> `mesh` -> `firewall` -> `discovery` -> `tls` -> `ingress` -> `logging` -> `metrics` ->
`backup` -> `maintenance`):

```sh
# List all available traits and their priority order
./libscript.sh trait list

# Apply or verify specific traits on the current host or target sysroot
./libscript.sh trait apply storage
./libscript.sh trait apply mesh
./libscript.sh trait apply firewall
./libscript.sh trait apply backup
./libscript.sh trait verify firewall
./libscript.sh trait teardown ingress
```

### Stateful Component Hooks: Backup, Restore, Upgrade & Rollback (`_lib/_common/hooks.sh`)

```sh
# Physical & multi-tenant backups and point-in-time restores
./_lib/_common/hooks.sh --exec postgres backup /var/backups/postgres
./_lib/_common/hooks.sh --exec postgres restore /var/backups/postgres
./_lib/_common/hooks.sh --exec postgres backup_tenant --tenant-id acme_corp
./_lib/_common/hooks.sh --exec postgres restore_tenant --tenant-id acme_corp

# Stateful application/database version upgrade and atomic downgrade/rollback
./_lib/_common/hooks.sh --exec postgres upgrade 15 16
./_lib/_common/hooks.sh --exec postgres rollback 15 16

# Health probes, endpoint announcement, and periodic maintenance
./_lib/_common/hooks.sh --exec postgres probe readiness
./_lib/_common/hooks.sh --exec postgres announce
./_lib/_common/hooks.sh --exec postgres maintenance
```

---

## 10. Testing, Idempotency & Audit Matrix

Verify compliance, boot reliability, and idempotency locally before deploying:

```sh
# 1. Run static compliance audit across all shell and batch scripts
./devtools/audit/audit_standards.sh <path_to_script_or_directory>

# 2. Execute the 2x consecutive execution idempotency matrix
./tests/test_idempotency_matrix.sh

# 3. Headless QEMU boot verification tests for Linux, FreeBSD, and illumos
./tests/os_boot_test.sh build/disk.qcow2 60
./tests/freebsd_boot_test.sh build/freebsd.qcow2 60
./tests/illumos_boot_test.sh build/illumos.qcow2 60

# 4. Graphical desktop Wayland and PipeWire headless smoke test
./tests/os_gui_smoke_test.sh build/disk.qcow2

# 5. Air-gapped offline installation verification test
./tests/test_airgap_boot.sh

# 6. Aggregate test markers and update README compatibility table
./tests/update_results.sh
```
