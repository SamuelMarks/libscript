# Stack Dependency & Download Pipeline Commands (`cli/commands/deps/`)

## Overview

`cli/commands/deps/` resolves and installs multi-component dependency graphs declared in
`libscript.json` manifests and processes checksum-verified batch artifact downloads.

## Scripts

- **`install.{sh,cmd,ps1}`** (`./libscript.sh install-deps`): Evaluates `deps` / `dependencies` in
  `libscript.json` via `engine/solver/resolve_stack.*` and provisions required `T1`/`T2` components
  idempotently with configurable reuse or isolation policies.
- **`process_downloads.{sh,cmd,ps1}`** (`./libscript.sh process-downloads`): Executes queued
  artifact downloads through `engine/common/pkg_mgr.{sh,cmd}`, enforcing SHA-256/SHA-512 checksum
  verification (`_lib/checksums.txt`) and air-gapped cache lookups (`LIBSCRIPT_CACHE_DIR`).

## Usage

```sh
./libscript.sh install-deps libscript.json
./libscript.sh process-downloads
```

```cmd
.\libscript.cmd install-deps libscript.json
.\libscript.cmd process-downloads
```
