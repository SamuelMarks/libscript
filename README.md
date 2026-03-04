# LibScript

## Purpose & Current State

**Purpose**: This document serves as the main entrypoint and high-level overview of the LibScript project, providing quick start instructions, links to other core documentation, and the current CI status. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager across Linux, macOS, DOS, and Windows. It features a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`), supports generating deployment configurations (Docker, MSI, InnoSetup, NSIS), handles semantic versioning, and provides native background serving. Recent updates have stabilized Windows installer generation and expanded macOS native service provisioning.

## Overview

LibScript provides a unified interface (`libscript.sh`, `libscript.cmd`, or `libscript.bat`) to install a wide variety of "components" ranging from language compilers (Rust, Go, Python) to databases (PostgreSQL, Valkey) to entire applications (JupyterHub).

It embraces a philosophy of transparent, inspectable shell scripts that are composable and idempotent. By utilizing native package managers (`apt`, `dnf`, `apk`, `brew`, `pacman`, etc.) where appropriate and falling back to direct downloads or source builds, LibScript bridges the gap between ad-hoc setup scripts and heavyweight configuration management tools like Ansible or Chef.

## Core Documentation

To understand the project better, consult the following guides:

- **[USAGE.md](USAGE.md):** How to use LibScript to install components on your system.
- **[ARCHITECTURE.md](ARCHITECTURE.md):** The internal structure, lifecycle, and design patterns of LibScript components.
- **[DEVELOPING.md](DEVELOPING.md):** How to contribute and add new components to the library.
- **[DEPENDENCIES.md](DEPENDENCIES.md):** Details on the cross-platform package manager abstraction.
- **[WINDOWS.md](WINDOWS.md):** Specific information regarding Windows and DOS support (Batch and PowerShell).
- **[TEST.md](TEST.md):** Information on the test suite, CI workflows, and local testing.
- **[WHY.md](WHY.md):** The philosophy and rationale behind creating LibScript.

## Quick Start

```sh
# List all available components
./libscript.sh list

# Search for a component
./libscript.sh search python

# Install a component (e.g., Rust)
./libscript.sh install rust latest

# View options for a component
./libscript.sh install rust latest --help
```

### Extended Command Set
The entire package ecosystem natively hooks the following runtime commands across Linux `sh` and Windows `cmd`:
- `install <package> <version>` : Download and Setup locally (Use `--prefix` to relocate).
- `run <package> <version> [args...]` : Bind the local execution logic to an arbitrary shell argument string directly.
- `exec <package> <version> <cmd> [args...]` : Force `$PATH` updates targeting configured components.
- `which <package> <version>` : Query internally installed bins natively.
- `ls <package>` : Scan installed versions.
- `ls-remote <package>` : Poll upstream sources.

A global caching protocol ensures tools download directly to `$LIBSCRIPT_ROOT_DIR/cache/downloads`. You can enforce system-wide bounds by using `--cache-dir=<folder>`.
## CI Checks Matrix

| Component | Ubuntu | macOS | Windows |
|---|---|---|---|
| `app/_storage/celery` | ✅ | ✅ | ❌ |
| `app/third_party/firecrawl` | ✅ | ✅ | ❌ |
| `app/third_party/jupyterhub` | ✅ | ✅ | ❌ |
| `app/third_party/openvpn` | ✅ | ✅ | ❌ |
| `app/third_party/serve-actix-diesel-auth-scaffold` | ✅ | ✅ | ❌ |
| `_lib/_git` | ✅ | ✅ | ✅ |
| `_lib/_server/caddy` | ✅ | ✅ | ✅ |
| `_lib/_server/docker` | ✅ | ✅ | ✅ |
| `_lib/_server/kubernetes_k0s` | ✅ | ❌ | ❌ |
| `_lib/_server/kubernetes_thw` | ✅ | ✅ | ❌ |
| `_lib/_server/nginx` | ✅ | ✅ | ❌ |
| `_lib/_server/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_server/python` | ✅ | ✅ | ✅ |
| `_lib/_server/rust` | ✅ | ✅ | ✅ |
| `_lib/_storage/etcd` | ✅ | ✅ | ❌ |
| `_lib/_storage/mongodb` | ✅ | ✅ | ✅ |
| `_lib/_storage/postgres` | ✅ | ✅ | ❌ |
| `_lib/_storage/rabbitmq` | ✅ | ✅ | ❌ |
| `_lib/_storage/sqlite` | ✅ | ✅ | ✅ |
| `_lib/_storage/valkey` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/bun` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/c` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/cc` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/cpp` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/csharp` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/deno` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/elixir` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/go` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/java` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/jq` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/kotlin` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/php` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/python` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/ruby` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/rust` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/sh` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/swift` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/wait4x` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/zig` | ✅ | ✅ | ✅ |
