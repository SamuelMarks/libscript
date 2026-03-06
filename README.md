# LibScript

[![CI Status](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

LibScript is a cross-platform software provisioning framework, stack generator, and universal version manager. It operates entirely on zero-dependency shell scripts (`sh`, `cmd`, `bat`), providing a lightweight alternative to heavy configuration managers and a native complement to containerized environments.

## Core Capabilities

- **Universal Version Manager:** LibScript functions powerfully as a local version manager for individual languages and tools (similar to `rvm`, `nvm`, `pyenv`, `uv`), while also acting as a global version manager that orchestrates the entire system.
- **Stack Building & Orchestration:** You can invoke the global version manager `libscript` to seamlessly compose and build much bigger, complex stacks such as WordPress, Open edX, Nextcloud, custom applications, and more.
- **Native Provisioning:** Run stack deployments directly on the host hardware without container virtualization overhead.
- **Artifact Generation:** Use the `package_as` engine to parse your local stack and automatically generate structured `Dockerfile`s or `docker-compose.yml` configurations.
- **Cross-Platform Installers:** Dynamically compile a generic stack into a native installer for various platforms:
  - Windows: MSI (via WiX), InnoSetup, NSIS
  - Linux: DEB, RPM, APK
  - FreeBSD: TXZ
  - macOS: PKG, DMG
- **Declarative Stacks:** Define stacks (like LAMP, WAMP, or MEAN) using `libscript.json`. The framework handles cross-platform dependency mapping and environment variable configuration automatically.
- **Zero-Dependency Architecture:** Requires no Python, Ruby, or Go agents to bootstrap.

## Lifecycle Commands

LibScript provides a unified interface for managing individual components or entire stacks across platforms.

**Unix (Linux/macOS):**
```sh
./libscript.sh install <COMPONENT> [VERSION]
./libscript.sh start <COMPONENT>
./libscript.sh stop <COMPONENT>
./libscript.sh uninstall <COMPONENT>
./libscript.sh package_as docker <COMPONENT>
```

**Windows:**
```cmd
libscript.cmd install <COMPONENT> [VERSION]
libscript.cmd start <COMPONENT>
libscript.cmd stop <COMPONENT>
libscript.cmd uninstall <COMPONENT>
libscript.cmd package_as msi <COMPONENT>
```

## Quick Start

List the supported components and toolchains:

```sh
./libscript.sh list
```

Install a component directly (e.g., Node.js):

```sh
./libscript.sh install nodejs 20
```

For more details on building complex stacks and utilizing the generator engine, refer to `USAGE.md` and the individual `README.md` files located in each component directory.

## CI Checks Matrix

[![CI](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

| Component | Ubuntu | macOS | Windows |
|---|---|---|---|
| `app/_storage/celery` | ✅ | ✅ | ⏭️ |
| `app/third_party/firecrawl` | ✅ | ✅ | ⏭️ |
| `app/third_party/jupyterhub` | ✅ | ✅ | ⏭️ |
| `app/third_party/openvpn` | ✅ | ✅ | ⏭️ |
| `app/third_party/serve-actix-diesel-auth-scaffold` | ✅ | ⏭️ | ⏭️ |
| `app/third_party/wordpress` | ❓ | ⏭️ | ⏭️ |
| `_lib/_bootstrap/7zip` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/apk` | ✅ | ⏭️ | ✅ |
| `_lib/_bootstrap/brew` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/busybox` | ✅ | ⏭️ | ✅ |
| `_lib/_bootstrap/choco` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/curl` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/dash` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/msys2` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/nix` | ✅ | ❓ | ⏭️ |
| `_lib/_bootstrap/pkgx` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/powershell` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/scoop` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/wget` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/winget` | ✅ | ✅ | ✅ |
| `_lib/_git` | ✅ | ✅ | ✅ |
| `_lib/_server/caddy` | ✅ | ✅ | ⏭️ |
| `_lib/_server/docker` | ✅ | ⏭️ | ✅ |
| `_lib/_server/fluentbit` | ✅ | ❓ | ❓ |
| `_lib/_server/httpd` | ✅ | ✅ | ❓ |
| `_lib/_server/iis` | ❓ | ⏭️ | ✅ |
| `_lib/_server/kubernetes_k0s` | ✅ | ⏭️ | ⏭️ |
| `_lib/_server/kubernetes_thw` | ❓ | ⏭️ | ⏭️ |
| `_lib/_server/nginx` | ✅ | ✅ | ⏭️ |
| `_lib/_server/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_server/openbao` | ❓ | ✅ | ❓ |
| `_lib/_server/python` | ✅ | ✅ | ✅ |
| `_lib/_server/rust` | ✅ | ⏭️ | ✅ |
| `_lib/_storage/etcd` | ✅ | ✅ | ⏭️ |
| `_lib/_storage/mariadb` | ✅ | ✅ | ✅ |
| `_lib/_storage/mongodb` | ❓ | ✅ | ✅ |
| `_lib/_storage/postgres` | ❓ | ❓ | ⏭️ |
| `_lib/_storage/rabbitmq` | ✅ | ✅ | ⏭️ |
| `_lib/_storage/sqlite` | ✅ | ✅ | ✅ |
| `_lib/_storage/valkey` | ❓ | ✅ | ✅ |
| `_lib/_toolchain/bun` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/c` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/cc` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/cpp` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/csharp` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/deno` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/elixir` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/go` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/java` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/jq` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/kotlin` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/php` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/python` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/ruby` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/rust` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/sh` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/swift` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/wait4x` | ✅ | ✅ | ❓ |
| `_lib/_toolchain/zig` | ❓ | ✅ | ✅ |
