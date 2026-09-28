# Roadmap

LibScript aims to become the universal substrate for software delivery, independent of cloud vendor
or operating system.

## Phase 3: Advanced PaaS & Cluster Mesh (Current)

- [ ] High-availability cluster orchestration blueprints (Master/Slave election, Raft-based state,
      Cross-cloud mesh).
- [ ] Automated global load balancer and reverse proxy configuration.
- [ ] Provider Expansion: Add support for DigitalOcean, Linode, and Vultr to the multicloud wrapper.
- [ ] Unified Deployment Grammar: A high-level DSL (extending `libscript.json`) to describe a
      globally distributed stack.
- [ ] Encrypted cross-node mesh networking / Zero-Trust Sidecars (WireGuard, Tailscale).
- [ ] Git-driven deployment workflows (`libscript deploy`).
- [x] Cross-cloud persistent volume and state management.

## Phase 4: Hardware & Observability (Next)

- [ ] Hardware-Aware Optimization: Automatically tuning component installations based on detected
      hardware (CPU instructions, NVMe presence).
- [x] Terminal User Interface (TUI) for stack and PaaS management via `package-as TUI`.
- [ ] Lightweight, decentralized Web Dashboard / Control Plane for real-time monitoring and resource
      management.
- [ ] Integrated log aggregation and health monitoring.
- [ ] Real-time multicloud resource cost and usage reporting.

## Phase 5: Hardware Acceleration & AI Infrastructure (Current)

- [x] Abstracted provisioning for TPU and GPU Virtual Machines.
- [x] GKE integration for distributed AI workloads via XPK.
- [x] Automation for inference engines (vLLM, JetStream).
- [ ] Bare-metal generic GPU passthrough setup for local development.

## Phase 6: FreeBSD-Based Modular Distribution & Verification Matrix

- [x] Specification & schema (`execution-plan.freebsd.schema.json`) with modular profiles.
- [x] Pluggable Init Systems (`bsd-rc`, `openrc`, `runit`, `s6`, `dinit`).
- [x] Display & Desktop modular staging (Wayland, X11, Sway, XFCE4, Plasma 6, seatd, PipeWire).
- [x] Multi-format disk image export (Raw GPT, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- [x] Headless boot, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency test harness.
- [x] Vagrant-only multi-platform verification matrix across `{macOS, Windows, FreeBSD, SunOS, Linux}`.

## Phase 7: Illumos-Based Modular Distribution & Verification Matrix

- [x] Specification & schema (`execution-plan.illumos.schema.json`) with modular profiles (`minimal-server`, `zfs-cloud`, `desktop-mate-x11`, `desktop-xfce-x11`, `cde-retro-x11`, `hardened-runit`, `pkgsrc-developer`).
- [x] Pluggable Init Systems (`smf`, `runit`, `s6`, `dinit`, `inittab-sysv`).
- [x] Display & Desktop modular staging (X11 Xorg, MATE, XFCE4, CDE, LightDM, SLiM, XDM, Boomer kernel audio).
- [x] Canonical ZFS root pool (`rpool`) dataset layout and `/etc/vfstab` integration.
- [x] Multi-format disk image export (Raw GPT/VTOC, QCOW2, Vagrant `.box`, VHD, VMDK, ISO).
- [x] Headless boot milestone smoketests, GUI smoketests, Vagrant lifecycle, and 2-pass idempotency test harness.
- [x] Vagrant-only multi-platform verification matrix across `{macOS, Windows, FreeBSD, SunOS, Linux}`.


_For completed phases (Phase 1 and 2), please see the [CHANGELOG.md](CHANGELOG.md)._
