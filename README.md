# LibScript

[![CI Status](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning. It functions as a comprehensive global and per-component package manager across Linux, macOS, DOS, and Windows.

## Key Features

- **Cross-Platform Provisioning**: Works seamlessly across Linux (Ubuntu, Debian, Alpine, RHEL, etc.), macOS, and Windows (Batch and PowerShell).
- **Unified Interface**: Use `libscript.sh`, `libscript.cmd`, or `libscript.bat` to manage your environment intuitively.
- **Vast Component Library**:
  - **Toolchains**: Install modern toolchains natively (Rust, Go, Python, Node.js, C, C++, Zig, Java, PHP, Ruby, Bun, Deno, Swift, etc.).
  - **Servers & Web**: Provision servers like Caddy, Nginx, Docker, Node.js, and Kubernetes (k0s, thw).
  - **Databases & Storage**: Effortlessly stand up PostgreSQL, MongoDB, SQLite, Valkey, Etcd, RabbitMQ, and more.
  - **Third-Party Applications**: Deploy complex applications and services like JupyterHub, OpenVPN, Firecrawl, and Celery stacks.
- **Native Package Manager Abstraction**: Intelligently utilizes underlying package managers (`apt`, `dnf`, `apk`, `brew`, `pacman`, `choco`, `winget`) when available, falling back to direct binary downloads or building from source.
- **Deployment & Config Generation**: Autogenerates deployment formats from configurations. Supports creating Dockerfiles (`debian.Dockerfile`, `alpine.Dockerfile`), Windows installers (MSI, InnoSetup, NSIS), and Vagrant test beds out-of-the-box.
- **Semantic Versioning & Scoping**: Resolves and installs specific versions of tools. Caches tools globally (in `$LIBSCRIPT_ROOT_DIR/cache/downloads`) or creates reproducible local environments with the `--prefix` option.
- **Idempotent & Composable**: Core execution is strictly inspectable, deterministic, and safe to re-run.

## Quick Start

```sh
# List all available components
./libscript.sh list

# Search for a specific component
./libscript.sh search nodejs

# Install a component globally or prefixed
./libscript.sh install rust latest
./libscript.sh install rust 1.70.0 --prefix=/opt/myenv

# Run a command in the environment of the tool without modifying global $PATH
./libscript.sh run python latest --version

# View installation options for a component
./libscript.sh install rust latest --help
```

### Command Set

The core ecosystem supports the following operations across all OS environments:
- `install <package> <version>` : Download and setup locally.
- `run <package> <version> [args...]` : Bind the local execution logic to an arbitrary shell argument string directly.
- `exec <package> <version> <cmd> [args...]` : Force `$PATH` updates targeting configured components.
- `which <package> <version>` : Query natively installed binary paths.
- `ls <package>` : Scan installed versions on the system.
- `ls-remote <package>` : Poll upstream sources for available versions.

## System Architecture

LibScript bridges the gap between ad-hoc setup scripts and heavyweight configuration management tools (like Ansible, Chef, or Puppet). Instead of requiring a runtime language or agent, it uses POSIX `sh` on Unix and `cmd`/`bat` on Windows.

- **`_lib/`**: Contains core reusable toolchains, storage solutions, server definitions, and daemon service managers (Systemd, OpenRC, Windows Services).
- **`app/`**: Compositions of complex third-party applications orchestrating multiple dependencies.
- **`netctl/`**: Built-in network control tools to manage reverse proxies and web application setups.

To delve into the internals, check out the [Architecture Guide](ARCHITECTURE.md) and our design rationale in [WHY.md](WHY.md).

## Core Documentation

Explore these detailed guides to leverage the full power of LibScript:

- **[USAGE.md](USAGE.md)**: Deep dive into usage patterns, environment scoping, and flags.
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Explore the internal directory structure, module lifecycles, and design patterns.
- **[DEPENDENCIES.md](DEPENDENCIES.md)**: How LibScript handles multi-OS package dependencies.
- **[WINDOWS.md](WINDOWS.md)**: Specific nuances and constraints for Windows/DOS and PowerShell operations.
- **[DEVELOPING.md](DEVELOPING.md)**: A guide for contributing and developing new LibScript components.
- **[TEST.md](TEST.md)**: Information on Vagrant local testing and our CI workflows.

## CI Checks Matrix

[![CI](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

| Component | Ubuntu | macOS | Windows |
|---|---|---|---|
| `app/_storage/celery` | ✅ | ✅ | ⏭️ |
| `app/third_party/firecrawl` | ✅ | ✅ | ⏭️ |
| `app/third_party/jupyterhub` | ✅ | ✅ | ⏭️ |
| `app/third_party/openvpn` | ✅ | ✅ | ⏭️ |
| `app/third_party/serve-actix-diesel-auth-scaffold` | ✅ | ✅ | ⏭️ |
| `_lib/_git` | ✅ | ✅ | ✅ |
| `_lib/_server/caddy` | ✅ | ✅ | ✅ |
| `_lib/_server/docker` | ✅ | ✅ | ✅ |
| `_lib/_server/kubernetes_k0s` | ✅ | ⏭️ | ⏭️ |
| `_lib/_server/kubernetes_thw` | ✅ | ⏭️ | ⏭️ |
| `_lib/_server/nginx` | ✅ | ✅ | ⏭️ |
| `_lib/_server/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_server/python` | ✅ | ✅ | ✅ |
| `_lib/_server/rust` | ✅ | ⏭️ | ✅ |
| `_lib/_storage/etcd` | ✅ | ✅ | ⏭️ |
| `_lib/_storage/mongodb` | ✅ | ✅ | ✅ |
| `_lib/_storage/postgres` | ✅ | ✅ | ⏭️ |
| `_lib/_storage/rabbitmq` | ✅ | ✅ | ⏭️ |
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
