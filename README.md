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
| `stacks/task-queues/celery` | ✅ | ✅ | ⏭️ |
| `stacks/cms/drupal` | ❓ | ❓ | ❓ |
| `stacks/crawlers/firecrawl` | ✅ | ✅ | ⏭️ |
| `stacks/cms/joomla` | ❓ | ❓ | ❓ |
| `stacks/data-science/jupyterhub` | ✅ | ✅ | ⏭️ |
| `stacks/ecommerce/magento` | ❓ | ❓ | ❓ |
| `stacks/collaboration/nextcloud` | ❓ | ❓ | ❓ |
| `stacks/erp/odoo` | ❓ | ❓ | ❓ |
| `stacks/networking/openvpn` | ✅ | ✅ | ⏭️ |
| `stacks/forums/phpbb` | ❓ | ❓ | ❓ |
| `stacks/ecommerce/prestashop` | ❓ | ❓ | ❓ |
| `stacks/scaffolds/serve-actix-diesel-auth-scaffold` | ✅ | ⏭️ | ⏭️ |
| `stacks/ecommerce/woocommerce` | ❓ | ❓ | ❓ |
| `stacks/cms/wordpress` | ❓ | ⏭️ | ⏭️ |
| `_lib/utilities/7zip` | ✅ | ✅ | ✅ |
| `_lib/package-managers/apk` | ✅ | ⏭️ | ✅ |
| `_lib/package-managers/brew` | ✅ | ✅ | ✅ |
| `_lib/utilities/busybox` | ✅ | ⏭️ | ✅ |
| `_lib/package-managers/choco` | ✅ | ✅ | ✅ |
| `_lib/utilities/curl` | ✅ | ✅ | ✅ |
| `_lib/utilities/dash` | ✅ | ✅ | ✅ |
| `_lib/package-managers/msys2` | ✅ | ✅ | ✅ |
| `_lib/package-managers/nix` | ✅ | ❓ | ⏭️ |
| `_lib/package-managers/pkgx` | ✅ | ✅ | ✅ |
| `_lib/utilities/powershell` | ✅ | ✅ | ✅ |
| `_lib/package-managers/scoop` | ✅ | ✅ | ✅ |
| `_lib/utilities/wget` | ✅ | ✅ | ✅ |
| `_lib/package-managers/winget` | ✅ | ✅ | ✅ |
| `_lib/git-servers` | ✅ | ✅ | ✅ |
| `_lib/web-servers/caddy` | ✅ | ✅ | ⏭️ |
| `_lib/orchestration/docker` | ✅ | ⏭️ | ✅ |
| `_lib/logging/fluentbit` | ✅ | ❓ | ❓ |
| `_lib/web-servers/httpd` | ✅ | ✅ | ❓ |
| `_lib/web-servers/iis` | ❓ | ⏭️ | ✅ |
| `_lib/orchestration/kubernetes_k0s` | ✅ | ⏭️ | ⏭️ |
| `_lib/orchestration/kubernetes_thw` | ❓ | ⏭️ | ⏭️ |
| `_lib/web-servers/nginx` | ✅ | ✅ | ⏭️ |
| `_lib/languages/nodejs_server` | ✅ | ✅ | ✅ |
| `_lib/security/openbao` | ❓ | ✅ | ❓ |
| `_lib/languages/python_server` | ✅ | ✅ | ✅ |
| `_lib/languages/rust_server` | ✅ | ⏭️ | ✅ |
| `_lib/databases/etcd` | ✅ | ✅ | ⏭️ |
| `_lib/databases/mariadb` | ✅ | ✅ | ✅ |
| `_lib/databases/mongodb` | ❓ | ✅ | ✅ |
| `_lib/databases/postgres` | ❓ | ❓ | ⏭️ |
| `_lib/message-brokers/rabbitmq` | ✅ | ✅ | ⏭️ |
| `_lib/databases/sqlite` | ✅ | ✅ | ✅ |
| `_lib/caches/valkey` | ❓ | ✅ | ✅ |
| `_lib/languages/bun` | ✅ | ✅ | ❓ |
| `_lib/languages/c` | ✅ | ✅ | ❓ |
| `_lib/languages/cc` | ✅ | ✅ | ❓ |
| `_lib/languages/composer` | ❓ | ❓ | ❓ |
| `_lib/languages/cpp` | ✅ | ✅ | ❓ |
| `_lib/languages/csharp` | ✅ | ✅ | ❓ |
| `_lib/languages/deno` | ✅ | ✅ | ❓ |
| `_lib/languages/elixir` | ✅ | ✅ | ❓ |
| `_lib/languages/go` | ✅ | ✅ | ❓ |
| `_lib/languages/java` | ✅ | ✅ | ❓ |
| `_lib/utilities/jq` | ✅ | ✅ | ✅ |
| `_lib/languages/kotlin` | ✅ | ✅ | ❓ |
| `_lib/languages/nodejs` | ✅ | ✅ | ✅ |
| `_lib/languages/php` | ✅ | ✅ | ❓ |
| `_lib/languages/python` | ✅ | ✅ | ✅ |
| `_lib/languages/ruby` | ✅ | ✅ | ❓ |
| `_lib/languages/rust` | ✅ | ✅ | ❓ |
| `_lib/languages/sh` | ✅ | ✅ | ❓ |
| `_lib/languages/swift` | ✅ | ✅ | ❓ |
| `_lib/utilities/wait4x` | ✅ | ✅ | ❓ |
| `_lib/languages/zig` | ❓ | ✅ | ✅ |
