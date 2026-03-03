# LibScript

## Purpose & Current State

**Purpose**: This document serves as the main entrypoint and high-level overview of the LibScript project, providing quick start instructions, links to other core documentation, and the current CI status. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

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
## CI Run Results

| Job Name | Conclusion | Link |
|---|---|---|
| app/third_party/serve-actix-diesel-auth-scaffold on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008423) |
| _lib/_server/kubernetes_k0s on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008429) |
| app/_storage/celery on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008431) |
| app/third_party/firecrawl on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008434) |
| app/third_party/openvpn on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008437) |
| app/third_party/jupyterhub on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008438) |
| _lib/_storage/valkey on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008443) |
| _lib/_server/nodejs on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008444) |
| _lib/_git on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008449) |
| _lib/_server/rust on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008452) |
| _lib/_server/kubernetes_thw on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008453) |
| _lib/_server/nginx on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008458) |
| _lib/_toolchain/bun on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008460) |
| _lib/_toolchain/c on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008461) |
| _lib/_toolchain/deno on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008464) |
| _lib/_server/python on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008465) |
| _lib/_storage/rabbitmq on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008466) |
| _lib/_toolchain/cc on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008469) |
| _lib/_toolchain/java on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008470) |
| _lib/_storage/postgres on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008471) |
| _lib/_toolchain/go on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008472) |
| app/third_party/serve-actix-diesel-auth-scaffold on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008474) |
| _lib/_toolchain/csharp on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008476) |
| _lib/_toolchain/rust on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008478) |
| _lib/_toolchain/swift on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008479) |
| app/_storage/celery on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008482) |
| app/third_party/jupyterhub on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008486) |
| _lib/_toolchain/nodejs on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008487) |
| _lib/_toolchain/wait4x on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008488) |
| _lib/_storage/etcd on ubuntu-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008492) |
| _lib/_server/python on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008495) |
| _lib/_toolchain/php on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008497) |
| _lib/_server/rust on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008498) |
| _lib/_toolchain/jq on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008504) |
| _lib/_toolchain/python on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008505) |
| _lib/_toolchain/c on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008506) |
| app/third_party/firecrawl on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008508) |
| _lib/_server/nginx on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008509) |
| _lib/_storage/etcd on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008510) |
| _lib/_toolchain/ruby on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008512) |
| app/third_party/openvpn on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008514) |
| _lib/_git on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008516) |
| _lib/_storage/rabbitmq on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008518) |
| _lib/_server/kubernetes_thw on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008520) |
| _lib/_storage/valkey on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008523) |
| _lib/_toolchain/kotlin on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008526) |
| _lib/_toolchain/kotlin on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008527) |
| _lib/_toolchain/wait4x on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008528) |
| _lib/_toolchain/jq on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008530) |
| _lib/_toolchain/cpp on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008531) |
| _lib/_storage/valkey on windows-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008533) |
| _lib/_toolchain/sh on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008538) |
| _lib/_toolchain/kotlin on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008539) |
| _lib/_toolchain/c on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008540) |
| _lib/_toolchain/java on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008546) |
| _lib/_server/nodejs on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008549) |
| _lib/_toolchain/cc on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008550) |
| _lib/_toolchain/sh on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008551) |
| _lib/_toolchain/php on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008553) |
| _lib/_toolchain/bun on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008554) |
| _lib/_toolchain/csharp on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008557) |
| _lib/_git on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008558) |
| _lib/_toolchain/java on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008559) |
| _lib/_toolchain/swift on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008560) |
| _lib/_toolchain/go on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008561) |
| _lib/_toolchain/cpp on ubuntu-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008562) |
| _lib/_toolchain/swift on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008566) |
| _lib/_server/nodejs on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008567) |
| _lib/_server/rust on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008568) |
| _lib/_server/python on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008569) |
| _lib/_toolchain/csharp on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008570) |
| _lib/_toolchain/cpp on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008572) |
| _lib/_toolchain/ruby on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008573) |
| _lib/_toolchain/rust on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008574) |
| _lib/_toolchain/python on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008575) |
| _lib/_toolchain/deno on windows-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008576) |
| _lib/_toolchain/jq on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008577) |
| _lib/_toolchain/rust on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008581) |
| _lib/_toolchain/ruby on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008582) |
| _lib/_storage/postgres on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008583) |
| _lib/_toolchain/go on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008586) |
| _lib/_toolchain/sh on windows-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008589) |
| _lib/_toolchain/wait4x on windows-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008590) |
| _lib/_toolchain/cc on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008593) |
| _lib/_toolchain/nodejs on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008597) |
| _lib/_toolchain/php on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008603) |
| _lib/_toolchain/nodejs on macos-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008606) |
| _lib/_toolchain/python on windows-latest | ✅ success | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008612) |
| _lib/_toolchain/bun on windows-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008613) |
| _lib/_toolchain/deno on macos-latest | ❌ failure | [View](https://github.com/SamuelMarks/libscript/actions/runs/22609212192/job/65508008633) |
