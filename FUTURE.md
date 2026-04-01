# Future Vision

LibScript aims to become the universal substrate for software delivery, independent of cloud vendor or operating system.

## Strategic Directions

- **Advanced Cluster Orchestration:** Moving beyond simple `node-group` provisioning to native support for high-availability patterns (Master/Slave election, Raft-based state, etc.) across all supported databases.
- **Provider Expansion:** Adding support for DigitalOcean, Linode, and Vultr to the multicloud wrapper.
- **Unified Deployment Grammar:** A high-level DSL (extending `libscript.json`) that can describe a globally distributed stack and provision it in one command.
- **Hardware-Aware Optimization:** Automatically tuning component installations based on the detected hardware (CPU instructions, NVMe presence, etc.).
- **TUI/Web Control Plane:** A robust, zero-dependency Terminal User Interface and a lightweight Web UI for real-time monitoring and resource management.
- **Zero-Trust Sidecars:** Native integration of service meshes and encrypted tunnels (WireGuard, Tailscale) between managed nodes.
