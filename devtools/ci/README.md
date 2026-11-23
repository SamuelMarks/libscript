# Continuous Integration & Release Automation (`devtools/ci/`)

## Overview

`devtools/ci/` contains deterministic CI workflow helpers for validating pre-commit idempotency,
assembling cross-platform release bundles, and publishing GitHub Release artifacts.

## Scripts

- **`precommit_dance.{sh,cmd}`**: Executes the repository pre-commit suite twice consecutively and
  asserts `git diff --exit-code` cleanliness so code generators and formatters
  (`generate_markdown_docs`, `prettier`, `cspell`, `audit_standards`, `audit_tiers`, `doc_coverage`)
  converge in a single pass.
- **`prepare_artifacts.{sh,cmd}`**: Collects, hashes (SHA-256), and organizes built `.msi`, `.deb`,
  `.rpm`, `.apk`, `.dmg`, `.pkg`, and ISO artifacts prior to release upload.
- **`publish_release.{sh,cmd}`**: Attaches verified build artifacts and checksum manifests to tagged
  releases in CI workflows.
