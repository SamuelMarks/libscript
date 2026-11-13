# Documentation Roadmap

This document outlines completed documentation milestones and upcoming documentation initiatives for
LibScript, maintaining 100% static documentation coverage (`devtools/audit/doc_coverage.sh`).

## Completed Documentation Deliverables

- [x] **100% Static Doc Coverage & Automated Schema Synchronization:** All component `README.md`
      files dynamically inherit variable tables from `vars.schema.json` and `base_vars.schema.json`,
      verified via `devtools/docs-gen/` and `devtools/audit/doc_coverage.{sh,cmd}`.
- [x] **Dynamic Platform Compatibility Matrices:** Automated OS/package-manager support tables
      across all 520+ subsystems (`devtools/docs-gen/generate_markdown_docs.*` and
      `tests/update_results.*`).
- [x] **Packaging & Branding Guides:** Documented `package-as` installer targets, online/offline
      air-gapped variants, and modular WiX/MSI chaining in
      [PACKAGING_BRANDING_GUIDE.md](PACKAGING_BRANDING_GUIDE.md), [WINDOWS_MSI.md](WINDOWS_MSI.md),
      and [WINDOWS.md](WINDOWS.md).
- [x] **Universal Live Installer Operator Guide:** Documented the `msi-rs` live multiboot installer,
      partitioning canvas, and multi-OS co-installation in
      [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).
- [x] **C11 REST API & OpenAPI 3.2.0 Documentation:** Documented the native C11 HTTP daemon
      (`c-rest-framework`) and OpenAPI 3.2.0 contract (`libscript-rest-api/openapi.yaml`) in
      [libscript-rest-api/README.md](libscript-rest-api/README.md),
      [libscript-rest-api/ARCHITECTURE.md](libscript-rest-api/ARCHITECTURE.md), and
      [libscript-rest-api/USAGE.md](libscript-rest-api/USAGE.md).
- [x] **Multi-Node Schedulers, Topologies, Traits & Cloud Experimentation:** Documented Tier 3.5 HA
      topologies ([topologies/README.md](topologies/README.md)), Tier 4 scheduler drivers
      ([payloads/README.md](payloads/README.md)), cross-cutting traits
      ([traits/README.md](traits/README.md)), and cloud Bento Vagrant matrix execution
      ([EXPERIMENTS.md](EXPERIMENTS.md)).
- [x] **Procedural HTML Documentation Generator:** Implemented static HTML portal synthesis in
      `devtools/generate_html_docs.{sh,cmd,ps1}` and `docs-web-template/`.

## Active & Future Objectives

1. **Hosted Searchable Documentation Portal:** Extend `devtools/generate_html_docs.{sh,cmd}` with
   client-side search indexing across all 320+ Tier 1 recipes, JSON schemas, and OpenAPI 3.2.0
   endpoints.
2. **illumos & FreeBSD Deep-Dive Internals:** Add dedicated architecture walkthroughs for ZFS boot
   environments (`beadm`), SMF service manifests, and FreeBSD `MAKEOBJDIRPREFIX` world cross-builds.
3. **Configuration Management Interoperability:** Document patterns for invoking LibScript recipes
   from existing Ansible, Chef, Puppet, or Terraform workflows during incremental migrations.
4. **End-to-End HA & AI Cookbooks:** Expand step-by-step runbooks around `topologies/openedx-ha/`,
   `topologies/postgres-ha/`, `topologies/gke-tpu-cluster/`, and `payloads/ai/*` (distributed XPK
   training, `vLLM`, and `JetStream` serving).
