# LibScript

[![CI Status](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

**LibScript** is a radically evolved, zero-dependency, cross-platform software provisioning framework and global package manager. It operates entirely on native shell scripts (`sh`, `cmd`, `bat`) to bring sophisticated configuration management, environment scoping, and application deployment to Linux, macOS, modern Windows, and legacy MS-DOS—without requiring external runtimes like Python or Ruby.

## What Makes LibScript Interesting?

- **Zero-Dependency Bootstrapping:** Needs nothing more than a POSIX shell or Windows command prompt. You can bootstrap a bare-metal machine instantly.
- **Universal Package Management:** Abstracted package manager layer (`pkg_mgr.sh`) seamlessly translates and delegates to `apt`, `apk`, `dnf`, `brew`, `pacman`, `choco`, or `winget`.
- **Deployment Generator (`package_as`):** Dynamically compile declarative manifests into Dockerfiles, `docker-compose.yml`, Debian/RPM/APK packages, or Windows Installers (MSI, InnoSetup, NSIS), and even interactive TUI installers.
- **Native Component Dependencies:** Applications can natively declare dependencies (e.g., `mariadb`, `caddy`) in their `vars.schema.json`. LibScript automatically resolves these via selectable strategies (`reuse`, `install-alongside`, `overwrite`)—fully exposed to interactive CLIs, env vars, and generated UI wizards.
- **Environment & Version Scoping:** Install multiple versions of toolchains and isolate their environments (using `--prefix` and `env`/`run`/`exec` commands).
- **Daemon Management:** Built-in translation to Systemd, OpenRC, and Windows Services for persistent databases and web servers.

## Features & Use-Cases

- **Toolchain Provisioning:** Natively install Rust, Go, Python, Node.js, C/C++, Zig, Java, PHP, Ruby, Bun, Deno, Swift, etc.
- **Server & Web Setup:** Instantly stand up Caddy, Nginx, Docker, Node.js, and lightweight Kubernetes (k0s).
- **Database & Storage Management:** Deploy PostgreSQL, MongoDB, SQLite, Valkey, Etcd, and RabbitMQ natively.
- **Third-Party App Deployment:** Provision JupyterHub, OpenVPN, Firecrawl, and Celery stacks directly to the host.
- **Declarative Environments:** Use `libscript.json` (via `install-deps`) to define and provision a complex stack in parallel.
- **Local Execution:** Run commands inside a component's isolated environment (`libscript.sh run python 3.11 --version`).

## Quick Start

```sh
# List components
./libscript.sh list

# Search for a component
./libscript.sh search nodejs

# Install globally or to a specific prefix
./libscript.sh install rust latest
./libscript.sh install postgres 16 --prefix=/opt/db

# Generate a Docker Compose stack from your environment
./libscript.sh package_as docker_compose postgres 16 redis latest > docker-compose.yml
```

## Documentation Index
- [ARCHITECTURE.md](ARCHITECTURE.md) - Internal execution lifecycle and directory structure.
- [DEPENDENCIES.md](DEPENDENCIES.md) - How cross-platform package resolution works.
- [DEVELOPING.md](DEVELOPING.md) - Guide to contributing and scaffolding new components.
- [USAGE.md](USAGE.md) - Deep dive into commands, flags, and JSON manifests.
- [WHY.md](WHY.md) - The philosophy behind zero-dependency shell scripting.
- [WINDOWS.md](WINDOWS.md) - Specifics on Windows, PowerShell, and legacy DOS support.
- [TEST.md](TEST.md) - Testing methodologies (CI, local, Vagrant).
- [ROADMAP.md](ROADMAP.md) / [FUTURE.md](FUTURE.md) / [IDEAS.md](IDEAS.md) - Project trajectory.

## CI Checks Matrix

[![CI](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

| Component | Ubuntu | macOS | Windows |
|---|---|---|---|
| `app/_storage/celery` | ❌ | ❌ | ⏭️ |
| `app/third_party/firecrawl` | ❌ | ❌ | ⏭️ |
| `app/third_party/jupyterhub` | ❌ | ❌ | ⏭️ |
| `app/third_party/openvpn` | ✅ | ✅ | ⏭️ |
| `app/third_party/serve-actix-diesel-auth-scaffold` | ❌ | ❌ | ⏭️ |
| `app/third_party/wordpress` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/7zip` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/apk` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/brew` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/busybox` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/choco` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/curl` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/dash` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/msys2` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/nix` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/pkgx` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/powershell` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/scoop` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/wget` | ❓ | ❓ | ❓ |
| `_lib/_bootstrap/winget` | ❓ | ❓ | ❓ |
| `_lib/_git` | ✅ | ✅ | ✅ |
| `_lib/_server/caddy` | ✅ | ✅ | ❌ |
| `_lib/_server/docker` | ✅ | ❌ | ✅ |
| `_lib/_server/fluentbit` | ✅ | ❌ | ❌ |
| `_lib/_server/httpd` | ✅ | ✅ | ❌ |
| `_lib/_server/iis` | ❓ | ❓ | ❓ |
| `_lib/_server/kubernetes_k0s` | ✅ | ⏭️ | ⏭️ |
| `_lib/_server/kubernetes_thw` | ❓ | ⏭️ | ⏭️ |
| `_lib/_server/nginx` | ✅ | ✅ | ⏭️ |
| `_lib/_server/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_server/openbao` | ❓ | ❓ | ❓ |
| `_lib/_server/python` | ✅ | ✅ | ✅ |
| `_lib/_server/rust` | ✅ | ⏭️ | ✅ |
| `_lib/_storage/etcd` | ❌ | ✅ | ⏭️ |
| `_lib/_storage/mariadb` | ❓ | ❓ | ❓ |
| `_lib/_storage/mongodb` | ❌ | ✅ | ✅ |
| `_lib/_storage/postgres` | ❌ | ❌ | ⏭️ |
| `_lib/_storage/rabbitmq` | ❌ | ❌ | ⏭️ |
| `_lib/_storage/sqlite` | ✅ | ✅ | ❌ |
| `_lib/_storage/valkey` | ❌ | ✅ | ❌ |
| `_lib/_toolchain/bun` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/c` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/cc` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/cpp` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/csharp` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/deno` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/elixir` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/go` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/java` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/jq` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/kotlin` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/nodejs` | ✅ | ❌ | ✅ |
| `_lib/_toolchain/php` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/python` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/ruby` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/rust` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/sh` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/swift` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/wait4x` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/zig` | ❌ | ✅ | ✅ |
