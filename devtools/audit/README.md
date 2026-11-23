# Codebase & Architecture Audit Utilities (`devtools/audit/`)

## Overview

`devtools/audit/` enforces LibScript's static engineering invariants, strict `T0`–`T5` + Orthogonal
Planes DAG boundaries, POSIX/Windows script parity, JSON Schema completeness, and 100% documentation
coverage. All core auditors run automatically in `.pre-commit-config.yaml` and CI.

## Audit Scripts

- **`audit_tiers.{sh,cmd}`**: Enforces the `T0`–`T5` + Orthogonal Planes (`Plane A: traits/`,
  `Plane B: experiments/`) architecture:
  - Strict downward-only imports (`T5 -> T4 -> T3 -> T2 -> T1 -> T0`); zero upward or circular
    sourcing.
  - Atomic `_lib/` purity: zero lateral cross-component sourcing inside `_lib/<cat>/<comp>/`.
  - Zero fractional tier strings (`1.5`, `3.5`) and zero legacy redirect shims.
- **`audit_standards.{sh,cmd,ps1}`**: Audits scripts and manifests for:
  - `POSIX_SHEBANG`, `SET_FEU_SAFETY`, `THIS_FILE_DANCE`, `RECURSION_GUARD`, `ROOT_DIR_RESOLUTION`
  - `WINDOWS_PARITY` / `POSIX_PARITY` (1:1 `.sh` and `.cmd` pairing) & `CLI_VERB_PARITY`
  - `BAN_EVAL` (no `eval` or `Invoke-Expression`) & `IDEMPOTENCY` (`mkdir -p`, `ln -sf`)
  - `RAW_NETWORK_FETCH` (all downloads must route through `engine/common/pkg_mgr.*`)
  - `EMPTY_SERVICE_STUB` (`service.{sh,cmd}` allowed strictly on `"service-daemon"` components)
  - `RAW_GCLOUD_TPU` & `EXP_IN_LIB`
- **`audit_posix.{sh,cmd}`**: Runs `shellcheck` and strict POSIX `/bin/sh` syntax validation.
- **`audit_cmd.{sh,cmd}`**: Validates Windows Batch `.cmd`/`.bat` syntax, labels, and `wincheck`
  rules.
- **`audit_version_manager.{sh,cmd}`**: Verifies `T1` version-manager lifecycle verbs (`ls-remote`,
  `install`, `ls`, `use`, `uninstall`, `env`, `which`) and `${LIBSCRIPT_HOME}` isolation.
- **`audit_schema_vars.{sh,cmd}`**: Verifies that environment variables consumed by scripts are
  declared and documented in `vars.schema.json`, `schemas/vars/*.schema.json`, or
  `base_vars.schema.json`.
- **`audit_stacks.{sh,cmd}`**: Validates stack, constellation, cluster, and profile JSON manifests
  against their respective JSON Schemas.
- **`doc_coverage.{sh,cmd}`**: Verifies 100% documentation coverage across component `README.md`
  files, schema property descriptions, CLI flags, functions, and script `## Overview` / `## Usage`
  headers.
- **`audit_windows.{sh,cmd,ps1}` & `ice_validation.{sh,cmd}`**: Runs Windows 11 VM installer audits
  and full 105-ICE Windows Installer `.msi` table validation (`darice.cub` / `msi-rs`).

## Usage

```sh
./devtools/audit/audit_tiers.sh --all
./devtools/audit/audit_standards.sh --all
./devtools/audit/doc_coverage.sh --strict
```
