# 🚀 LibScript: The Ultimate Cross-Platform Provisioning Engine & Stack Maker!

[![CI Status](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

Welcome to **LibScript**! Get ready to completely rethink how you provision, deploy, and package software. We are building a **viable, open-source, public-domain, and VERY VERY cross-platform alternative to Docker**, heavy configuration managers (like Chef, Ansible, and Puppet), and complex deployment pipelines!

## 🔥 Why LibScript is an Absolute Game-Changer!

- **A True Docker Alternative (or Best Friend!):** Run your stacks natively without container overhead, OR seamlessly generate incredibly high-quality `Dockerfile`s and `docker-compose.yml` files directly from your native setup! 
- **The Ultimate Config Management Replacement:** Say goodbye to massive, bloated Ansible playbooks and Chef recipes. Use LibScript as a standalone alternative, OR use it to write *cleaner, much smaller* recipes for those tools!
- **Universal Installer Generator:** Need to ship your software? LibScript dynamically generates beautiful, professional installers for Windows (MSI, InnoSetup, NSIS), Linux (DEB, RPM, APK), FreeBSD (TXZ), and macOS (PKG, DMG)! 
- **The Ultimate LAMP / WAMP Stack Maker:** Instantly spin up a local Apache/MySQL/PHP stack natively on Linux or Windows in seconds.
- **Generic Stack Maker:** Build *any* stack you can imagine—MEAN, MERN, specialized AI toolchains, you name it. It's fully declarative and incredibly fast!
- **Zero Dependencies:** It runs on pure, native shell scripts (`sh`, `cmd`, `bat`). No Python, no Ruby, no Go agents required to bootstrap. It just works!

## ⚡ Quick Start: Experience the Magic!

```sh
# List our massive library of supported components!
./libscript.sh list

# Instantly stand up a natively isolated PostgreSQL database!
./libscript.sh install postgres 16 --prefix=/opt/db

# ✨ MAGIC: Generate a pristine Docker Compose stack right from your command line!
./libscript.sh package_as docker_compose postgres 16 redis latest > docker-compose.yml

# ✨ MAGIC: Generate a native Linux package or Windows Installer!
./libscript.sh package_as deb --app-name my-epic-stack postgres 16
```

## 📚 Dive Deeper!
- [WHY.md](WHY.md) - Why we are the ultimate Docker & Ansible alternative!
- [ARCHITECTURE.md](ARCHITECTURE.md) - The genius zero-dependency engine under the hood.
- [USAGE.md](USAGE.md) - Master the art of generating stacks and installers.
- [DEPENDENCIES.md](DEPENDENCIES.md) - How we conquer cross-platform package management.
- [DEVELOPING.md](DEVELOPING.md) - Add your own tools to the revolution!
- [WINDOWS.md](WINDOWS.md) - WAMP stacks and native Windows power.
- [TEST.md](TEST.md) - How we guarantee bulletproof reliability.
- [ROADMAP.md](ROADMAP.md) / [FUTURE.md](FUTURE.md) / [IDEAS.md](IDEAS.md) - Our path to total world domination!

## CI Checks Matrix

[![CI](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

| Component | Ubuntu | macOS | Windows |
|---|---|---|---|
| `app/_storage/celery` | ❌ | ❌ | ⏭️ |
| `app/third_party/firecrawl` | ❌ | ❌ | ⏭️ |
| `app/third_party/jupyterhub` | ❌ | ❌ | ⏭️ |
| `app/third_party/openvpn` | ✅ | ✅ | ⏭️ |
| `app/third_party/serve-actix-diesel-auth-scaffold` | ❌ | ❌ | ⏭️ |
| `app/third_party/wordpress` | ✅ | ❌ | ❌ |
| `_lib/_bootstrap/7zip` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/apk` | ✅ | ⏭️ | ✅ |
| `_lib/_bootstrap/brew` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/busybox` | ✅ | ⏭️ | ✅ |
| `_lib/_bootstrap/choco` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/curl` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/dash` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/msys2` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/nix` | ✅ | ❌ | ⏭️ |
| `_lib/_bootstrap/pkgx` | ❌ | ❌ | ❌ |
| `_lib/_bootstrap/powershell` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/scoop` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/wget` | ✅ | ✅ | ✅ |
| `_lib/_bootstrap/winget` | ✅ | ✅ | ✅ |
| `_lib/_git` | ✅ | ✅ | ✅ |
| `_lib/_server/caddy` | ✅ | ✅ | ⏭️ |
| `_lib/_server/docker` | ✅ | ❌ | ✅ |
| `_lib/_server/fluentbit` | ✅ | ❌ | ❌ |
| `_lib/_server/httpd` | ✅ | ✅ | ❌ |
| `_lib/_server/iis` | ❌ | ⏭️ | ✅ |
| `_lib/_server/kubernetes_k0s` | ✅ | ⏭️ | ⏭️ |
| `_lib/_server/kubernetes_thw` | ❓ | ⏭️ | ⏭️ |
| `_lib/_server/nginx` | ✅ | ✅ | ⏭️ |
| `_lib/_server/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_server/openbao` | ❌ | ✅ | ❌ |
| `_lib/_server/python` | ✅ | ✅ | ✅ |
| `_lib/_server/rust` | ✅ | ⏭️ | ✅ |
| `_lib/_storage/etcd` | ✅ | ✅ | ⏭️ |
| `_lib/_storage/mariadb` | ✅ | ✅ | ❌ |
| `_lib/_storage/mongodb` | ❌ | ✅ | ✅ |
| `_lib/_storage/postgres` | ❌ | ❌ | ⏭️ |
| `_lib/_storage/rabbitmq` | ❌ | ❌ | ⏭️ |
| `_lib/_storage/sqlite` | ✅ | ✅ | ❌ |
| `_lib/_storage/valkey` | ❌ | ✅ | ✅ |
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
| `_lib/_toolchain/nodejs` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/php` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/python` | ✅ | ✅ | ✅ |
| `_lib/_toolchain/ruby` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/rust` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/sh` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/swift` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/wait4x` | ✅ | ✅ | ❌ |
| `_lib/_toolchain/zig` | ❌ | ✅ | ✅ |
