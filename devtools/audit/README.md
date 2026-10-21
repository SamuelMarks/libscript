# Codebase Audit Utilities

## Overview

Scripts for inspecting stacks, verifying component schemas, and validating standards across the
LibScript repository.

## Utilities

- `audit_standards.sh`: Audits files for strict adherence to LibScript engineering standards (POSIX
  `/bin/sh` compliance, `THIS_FILE=` preamble, Windows batch parity, eval prevention, idempotency
  patterns, and 100% doc block coverage).
- `doc_coverage.sh`: Audits documentation coverage across component `README.md` files, script header
  markdown docstrings (`.sh`, `.cmd`, `.ps1`), shell functions, batch labels, and JSON schemas, and
  updates the `% doc coverage` shield in `README.md` (`--update-readme`).
- `audit_stacks.sh`: Scans stack definitions for missing scripts, broken references, or schema
  errors.
- `audit_windows.sh`: Audits LibScript components on a Windows 11 VM to test installers and runtime
  compatibility.
