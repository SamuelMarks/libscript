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

### Installation Method Resolution Chain

When requesting a component, LibScript dynamically resolves the installation method using a smart
priority chain:

1. `libscript_native` (Default: isolated binary download or compilation into `${LIBSCRIPT_HOME}`)
2. `mise` (Rust-based toolchain manager fallback)
3. `asdf` (Classic plugin-based manager fallback)
4. `pkgx` (Isolated package runner fallback)
5. `vfox` (Version-Fox native Windows-friendly manager fallback)
6. `system` (OS-level package manager: `apt`, `apk`, `dnf`, `brew`, `winget`, `pkg`)

Override globally or per component:

```sh
# Global override
export LIBSCRIPT_DEFAULT_INSTALL_METHOD="pkgx"

# Per-component overrides
export PYTHON_INSTALL_METHOD="system"
export NODEJS_INSTALL_METHOD="libscript_native"
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

Available curated profiles:

- `linux-minimal-headless-musl.json`: Ultra-compact Musl/BusyBox server appliance.
- `linux-standard-server-glibc.json`: Production enterprise Glibc server with OpenSSH.
- `linux-desktop-sway-wayland.json`: Sway, Wayland, PipeWire, seatd, and greetd.
- `linux-desktop-hyprland.json`: Hyprland Wayland compositor with SDDM.
- `linux-desktop-kde-plasma.json`: KDE Plasma 6 desktop environment.
- `linux-desktop-xfce-x11.json`: Lightweight XFCE4 desktop on X11.
- `freebsd-server-standard.json`: FreeBSD 14.x base with ZFS root pool.
- `freebsd-desktop-xfce.json`: FreeBSD desktop with DRM KMS graphics drivers.
- `firecracker-microvm-appliance.json`: Minimalist appliance for sub-15ms microVM boots.
- `unikraft-nginx-redis.json`: Specialized single-purpose unikernel image.

---

## 3. Universal Artifact Packaging (`package-as`)

The `package-as` engine transforms your local stack, container root, or synthesized OS configuration
into deployable media:

### Operating System & Virtualization Formats

```sh
# 1. Raw flashable disk image for bare-metal drives (dd if=... of=/dev/sdX)
./libscript.sh package-as raw-img

# 2. Virtual machine disk images (compressed)
./libscript.sh package-as qcow2      # QEMU / KVM / Proxmox VE
./libscript.sh package-as vmdk       # VMware ESXi / Workstation
./libscript.sh package-as vdi        # VirtualBox

# 3. Hybrid live bootable ISO (UEFI + BIOS) with SquashFS and OverlayFS
./libscript.sh package-as iso

# 4. Bootable FreeBSD image with UFS or ZFS pools (for bhyve or bare metal)
./libscript.sh package-as bsd-img

# 5. Direct-kernel boot image for microVMs (Firecracker / Cloud-Hypervisor)
./libscript.sh package-as unikernel

# 6. Clean rootfs archives for OCI containers, LXC, or FreeBSD Jails
./libscript.sh package-as rootfs-tar
./libscript.sh package-as docker
```

### Native Application Installers

```sh
# Windows Installer (WiX MSI)
./libscript.sh package-as msi

# macOS Installer
./libscript.sh package-as pkg
./libscript.sh package-as dmg

# Linux Packages
./libscript.sh package-as deb        # Debian / Ubuntu
./libscript.sh package-as rpm        # Fedora / RHEL / CentOS
./libscript.sh package-as apk        # Alpine Linux

# Interactive Terminal Installer
./libscript.sh package-as tui
```

---

## 4. Declarative Stacks & Ingress (`libscript.json`)

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

## 5. Multicloud & AI Cluster Deployment (Tier 3)

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
# Provision a Google Cloud TPU VM with GCS FUSE and TensorBoard telemetry
export TPU_NAME="vllm-node"
export ACCELERATOR_TYPE="v4-8"
./stacks/ai-serving/tpu-vm-vllm/setup.sh
./stacks/ai-serving/tpu-vm-vllm/deploy.sh

# Launch distributed training across TPU Pod slices via GKE and XPK
xpk cluster create --cluster my-tpu-cluster --tpu-type=v5p-128
xpk workload create --workload train-job --cluster my-tpu-cluster --command "python3 train.py"
```

### Reverse Proxy & Ingress Management (`netctl`)

Use the standalone `netctl` routing abstraction to emit configurations directly:

```sh
# Emit an Nginx reverse proxy configuration with upstream SSL termination
./netctl.sh --listen 80 --listen 443 --proxy /api http://localhost:8000 --static / /var/www --emit nginx

# Emit an Apache virtualhost configuration
./netctl.sh --listen 80 --proxy / http://localhost:3000 --emit apache
```

---

## 6. Testing, Idempotency & Audit Matrix

Verify compliance, boot reliability, and idempotency locally before deploying:

```sh
# 1. Run static compliance audit across all shell and batch scripts
./devtools/audit/audit_standards.sh <path_to_script_or_directory>

# 2. Execute the 2x consecutive execution idempotency matrix
./tests/test_idempotency_matrix.sh

# 3. Headless QEMU boot verification test for synthesized OS disk images
./tests/os_boot_test.sh build/disk.qcow2 60

# 4. Graphical desktop Wayland and PipeWire headless smoke test
./tests/os_gui_smoke_test.sh build/disk.qcow2

# 5. Air-gapped offline installation verification test
./tests/test_airgap_boot.sh
```
