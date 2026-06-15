# Changelog

All notable changes to the LibScript framework are documented here.

## [Unreleased]

### Completed Initiatives

#### Phase 2: Multicloud PaaS Orchestration
- Unified `cloud` wrapper for AWS, Azure, and GCP utilizing native orchestration primitives (e.g., Azure VNets, NSGs, and VMs).
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