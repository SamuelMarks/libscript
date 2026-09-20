# Devtools CI Automation

## Overview

Continuous integration helper utilities and pre-commit automation scripts for LibScript.

## Utilities

- `precommit_dance.sh`: Runs linting, shell checking, batch verification, and formatting before
  commits.
- `prepare_artifacts.sh`: Validates built installer packages and generates `.sha256` checksum files
  (with Windows batch parity in `prepare_artifacts.cmd` and PowerShell in `prepare_artifacts.ps1`).
- `publish_release.sh`: Idempotently creates releases and attaches assets via GitHub CLI (with
  Windows batch parity in `publish_release.cmd` and PowerShell in `publish_release.ps1`).
