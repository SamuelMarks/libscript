# Codebase Audit Utilities

## Overview

Scripts for inspecting stacks, verifying component schemas, and validating standards across the
LibScript repository.

## Utilities

- `audit_standards.sh` / `audit_standards.cmd` / `audit_standards.ps1`: Audits files for strict
  adherence to LibScript engineering standards:
  - `POSIX_SHEBANG`, `SET_FEU_SAFETY`, `THIS_FILE_DANCE`, `RECURSION_GUARD`, `ROOT_DIR_RESOLUTION`
  - `WINDOWS_PARITY` / `POSIX_PARITY`: Enforces 1:1 `.sh` and `.cmd` script pairing
  - `RAW_NETWORK_FETCH`: Bans raw `curl`, `wget`, `aria2c`, `Invoke-WebRequest`,
    `Invoke-RestMethod`, `iwr`, `irm`, and `certutil -urlcache` outside `_lib/_common/pkg_mgr.*`
  - `RAW_PACKAGE_MANAGER`: Bans direct OS/language package manager mutations outside
    `_lib/_common/pkg_mgr.*` and `_lib/package-managers/*`
  - `UNNECESSARY_DOUBLE_QUOTES`: Enforces single quotes `'...'` for static literals in `.sh` scripts
  - `IDEMPOTENCY`, `BAN_EVAL`, `REMOTE_SAFETY`, `BATCH_HYGIENE`, `STACK_HYGIENE`,
    `CHECKSUM_INTEGRITY`, `JSON_VALIDITY`, `SCHEMA_DESCRIPTIONS`
- `audit_posix.sh` / `audit_posix.cmd`: Dedicated POSIX `/bin/sh` compliance, bashism prohibition,
  quoting hygiene, and Windows companion pairing audit.
- `audit_version_manager.sh` / `audit_version_manager.cmd`: Audits all
  `_lib/<category>/<component>/` directories for strict compliance with the Version Manager
  Contract.
- `audit_schema_vars.sh` / `audit_schema_vars.cmd` / `audit_schema_vars.ps1`: Verifies that every
  component-scoped (`<COMP>_*`) and global (`LIBSCRIPT_*`) configuration variable referenced in
  component scripts is declared and documented in `vars.schema.json` or `base_vars.schema.json`
  (`MISSING_JSON_VAR`).
- `doc_coverage.sh` / `doc_coverage.cmd` / `doc_coverage.ps1`: Audits documentation coverage across
  component `README.md` files, script header markdown docstrings (`.sh`, `.cmd`, `.ps1`), shell
  functions, batch labels, and JSON schemas, and updates the `% doc coverage` shield in `README.md`
  (`--update-readme`).
- `audit_stacks.sh` / `audit_stacks.cmd` / `audit_stacks.ps1`: Scans stack definitions for missing
  scripts, broken references, or schema errors.
- `audit_windows.sh` / `audit_windows.cmd` / `audit_windows.ps1`: Audits LibScript components on a
  Windows 11 VM to test installers and runtime compatibility.
- `ice_validation.sh` / `ice_validation.cmd`: Orchestrates Windows ICE validation for generated MSI
  packages.
