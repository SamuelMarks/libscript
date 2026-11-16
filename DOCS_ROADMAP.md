# Documentation Roadmap

This document outlines completed documentation milestones and upcoming documentation initiatives for
LibScript, maintaining 100% static documentation coverage (`devtools/audit/doc_coverage.sh`).

## Completed Documentation Deliverables

- [x] **100% Static Doc Coverage & Automated Schema Synchronization:** All component `README.md`
      files dynamically inherit variable tables from `vars.schema.json` and `base_vars.schema.json`,
      verified via `devtools/docs-gen/` and `devtools/audit/doc_coverage.{sh,cmd}`.
- [x] **Dynamic Platform Compatibility Matrices:** Automated OS/package-manager support tables
      across all 547+ documented components and 580+ subsystems
      (`devtools/docs-gen/generate_markdown_docs.*`, `experiments/os-component-matrix/`, and
      `tests/update_results.*`).
- [x] **Packaging, Unikernel Constellation & Cloud Marketplace Guides:** Documented `package-as`
      installer targets, UEFI/GPT cloud-boot unikernels, compliance-gated `publish-marketplace`
      workflows (`schemas/marketplace-offer.schema.json`), online/offline air-gapped variants, and
      modular WiX/MSI chaining in [PACKAGING_BRANDING_GUIDE.md](PACKAGING_BRANDING_GUIDE.md),
      [PAAS.md](PAAS.md), [WINDOWS_MSI.md](WINDOWS_MSI.md), and [WINDOWS.md](WINDOWS.md).
- [x] **ReactOS Synthesis & Native Windows/MS-DOS (`dos32`) Porting Specifications:** Documented
      modular ReactOS (`i686`/`x86_64`) synthesis (`execution-plan.reactos.schema.json`), quad-boot
      `msi-rs` live media, and the zero-emulation Windows PE & MS-DOS `dos32` binary porting
      architecture in [WINDOWS.md](WINDOWS.md), [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md),
      and [TODO_PORT_FOR_WIN.md](TODO_PORT_FOR_WIN.md).
- [x] **Universal Live Installer Operator Guide:** Documented the `msi-rs` live multiboot installer,
      partitioning canvas, and multi-OS co-installation in
      [LIVE_INSTALLER_GUIDE.md](LIVE_INSTALLER_GUIDE.md).
- [x] **C11 REST API & OpenAPI 3.2.0 Documentation:** Documented the native C11 HTTP daemon
      (`c-rest-framework`) and OpenAPI 3.2.0 contract (`libscript-rest-api/openapi.yaml`, including
      `/api/v1/experiments`, `/api/v1/marketplace/publish`, and capability introspection) in
      [libscript-rest-api/README.md](libscript-rest-api/README.md),
      [libscript-rest-api/ARCHITECTURE.md](libscript-rest-api/ARCHITECTURE.md), and
      [libscript-rest-api/USAGE.md](libscript-rest-api/USAGE.md).
- [x] **Multi-Node Schedulers, Topologies, Traits, RTOS & Open/Closed Experimentation:** Documented
      Tier 3.5 HA & unikernel topologies ([topologies/README.md](topologies/README.md)), Tier 4
      scheduler drivers including `tpu_vm` and `rtos_firmware`
      ([payloads/README.md](payloads/README.md)), cross-cutting traits including 4-role GCS ML
      storage ([traits/README.md](traits/README.md)), and the `experiments/<suite-id>/` empirical
      plugin architecture ([EXPERIMENTS.md](EXPERIMENTS.md),
      [experiments/README.md](experiments/README.md)).
- [x] **Procedural HTML Documentation Generator:** Implemented static HTML portal synthesis in
      `devtools/generate_html_docs.{sh,cmd,ps1}` and `docs-web-template/`.

## Active & Future Objectives

1. **Hosted Searchable Documentation Portal:** Extend `devtools/generate_html_docs.{sh,cmd}` with
   client-side search indexing across all 360+ Tier 1 recipes, 547+ documented components, 580+
   subsystems, JSON schemas, and OpenAPI 3.2.0 endpoints.
2. **illumos, FreeBSD & ReactOS Deep-Dive Internals:** Add dedicated architecture walkthroughs for
   ZFS boot environments (`beadm`), SMF service manifests, FreeBSD `MAKEOBJDIRPREFIX` world
   cross-builds, and ReactOS RosBE / FreeLoader internals.
3. **Configuration Management Interoperability:** Document patterns for invoking LibScript recipes
   from existing Ansible, Chef, Puppet, or Terraform workflows during incremental migrations.
4. **End-to-End HA & AI Cookbooks:** Expand step-by-step runbooks around `topologies/openedx-ha/`,
   `topologies/postgres-ha/`, `topologies/gke-tpu-cluster/`, and `payloads/ai/*` (distributed XPK
   training, `vLLM`, and `JetStream` serving).
