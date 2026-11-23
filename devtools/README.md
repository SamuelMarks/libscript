# Developer, Audit & Release Tooling (`devtools/`)

## Overview

`devtools/` houses repository quality gates, `T0`–`T5` architectural boundary auditors, automated
documentation generators, `msi-rs` live-installer builders, and headless Vagrant/GUI screenshot
verification harnesses.

## Subdirectories & Key Utilities

- [`audit/`](./audit/README.md): Static engineering standards (`audit_standards.*`), `T0`–`T5` DAG
  tier boundary auditor (`audit_tiers.*`), POSIX/Batch linters, version-manager contract verifier,
  schema variable auditor, ICE MSI validator, and 100% doc coverage gate (`doc_coverage.*`).
- [`ci/`](./ci/README.md): Pre-commit idempotency dance (`precommit_dance.*`), release artifact
  staging (`prepare_artifacts.*`), and release publication helpers.
- [`docs-gen/`](./docs-gen/README.md): Automated `vars.schema.json` Markdown table injector
  (`generate_markdown_docs.sh`, `inject_markers.sh`).
- **`generate_html_docs.{sh,cmd,ps1}`**: Compiles all repository Markdown guides and JSON Schemas
  into a static HTML documentation site using `docs-web-template/`.
- **`build_live_installer.{sh,cmd}` & `write_usb.{sh,cmd}`**: Builds universal `msi-rs` multiboot
  Live-CD / Live-USB ISOs across Linux, FreeBSD, illumos, and ReactOS.
- **`capture_*` & `verify_screenshots.{sh,cmd}`**: Automated GUI/browser screenshot capture and
  perceptual verification across MSI, Open edX, WordPress, and live-installer matrices.

## Usage

```sh
./devtools/audit/audit_standards.sh --all
./devtools/audit/audit_tiers.sh --all
./devtools/audit/doc_coverage.sh --strict
./devtools/docs-gen/generate_markdown_docs.sh
```
