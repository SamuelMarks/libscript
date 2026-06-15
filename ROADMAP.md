# Roadmap

LibScript aims to become the universal substrate for software delivery, independent of cloud vendor or operating system.

## Phase 3: Advanced PaaS & Cluster Mesh (Current)
- [ ] High-availability cluster orchestration blueprints (Master/Slave election, Raft-based state, Cross-cloud mesh).
- [ ] Automated global load balancer and reverse proxy configuration.
- [ ] Provider Expansion: Add support for DigitalOcean, Linode, and Vultr to the multicloud wrapper.
- [ ] Unified Deployment Grammar: A high-level DSL (extending `libscript.json`) to describe a globally distributed stack.
- [ ] Encrypted cross-node mesh networking / Zero-Trust Sidecars (WireGuard, Tailscale).
- [ ] Git-driven deployment workflows (`libscript deploy`).
- [x] Cross-cloud persistent volume and state management.

## Phase 4: Hardware & Observability (Next)
- [ ] Hardware-Aware Optimization: Automatically tuning component installations based on detected hardware (CPU instructions, NVMe presence).
- [x] Terminal User Interface (TUI) for stack and PaaS management via `package_as TUI`.
- [ ] Lightweight, decentralized Web Dashboard / Control Plane for real-time monitoring and resource management.
- [ ] Integrated log aggregation and health monitoring.
- [ ] Real-time multicloud resource cost and usage reporting.

*For completed phases (Phase 1 and 2), please see the [CHANGELOG.md](CHANGELOG.md).*