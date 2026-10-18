# Documentation Roadmap

This document outlines the planned improvements and ongoing initiatives for LibScript's
documentation. The goal is to provide clear, technically accurate guides for utilizing the
framework's native execution and generation capabilities.

## Current Objectives

- **Automated Schema Synchronization:** Ensure all `README.md` files dynamically inherit and display
  accurate variable tables from `vars.schema.json` and `base_vars.schema.json`. _(Implemented via
  `devtools/docs-gen`)_
- **Dynamic Compatibility Matrices:** Automatically detect and maintain "Platform Support" tables in
  component READMEs by inspecting execution scripts. _(Implemented via `devtools/docs-gen`)_
- **Generator Documentation:** Provide detailed examples of utilizing the `package-as` command to
  generate Dockerfiles, Docker Compose setups, and native OS installers (Windows, Linux, FreeBSD,
  macOS).
- **Universal Live Installer Documentation:** Document the `msi-rs` live multiboot installer
  architecture, console parameters, interactive canvas, and multi-OS co-installation in
  [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).
- **illumos Distribution Synthesis:** Document the illumos kernel, SMF services, and ZFS `rpool`
  hierarchy across OmniOS and OpenIndiana profiles.
- **REST API & OpenAPI Documentation:** Document the programmatic C++ HTTP microservice and OpenAPI
  3.0 contract in `libscript-rest-api/`.
- **Multi-Node Schedulers, Topologies & Traits Documentation:** Document Tier 3.5 HA topologies
  ([topologies/README.md](topologies/README.md)), Tier 4 scheduler drivers for Kubernetes, Mesos,
  and Nomad ([payloads/README.md](payloads/README.md)), and cross-cutting traits
  ([traits/README.md](traits/README.md)).

## Future Enhancements

1. **Procedural Web Docs Generation:** Expand the `generate_html_docs.sh` toolchain to synthesize an
   entire static documentation website utilizing the auto-generated markdown tables.
2. **Interactive Examples:** Provide interactive CLI or TUI examples within the documentation to
   demonstrate stack building.
3. **Configuration Management Integration:** Detail how LibScript can be called from existing tools
   (like Chef, Ansible, and Puppet) to simplify playbook complexity.
4. **Stack & Topology Templates:** Document common stack definitions (`libscript.json`), workload
   payloads (`payloads/`), and HA cluster blueprints (`topologies/`).
5. **Machine Learning Infrastructure:** Expand tutorials around `payloads/ai/*`,
   `topologies/gke-tpu-cluster/`, and `_lib/ml-training/` to demonstrate TPU/GPU provisioning,
   distributed XPK training, and vLLM/JetStream deployment workflows.
