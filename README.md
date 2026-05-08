# 🚀 LibScript: The Universal Provisioning Engine
**Native Power. Docker Optional. Zero YAML Bloat. Provision anything, anywhere.**

[![License](https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT%20OR%20CC0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![CI Tests](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml/badge.svg)](https://github.com/SamuelMarks/libscript/actions/workflows/ci.yml)

LibScript is a high-performance software provisioning framework and multicloud orchestrator. It’s built for engineers who want the reproducibility of containers with the raw performance of native execution—and the flexibility to switch between them in a single command.

---

## 🌟 Why LibScript?

Most configuration managers require a heavy runtime (Python, Ruby, Go) just to *start* working. LibScript doesn't. It's written in pure, battle-hardened POSIX shell and Windows CMD/PowerShell. It's as "bare metal" as it gets.

### 📦 "Every-Thing-is-a-Package-Manager"
LibScript's architecture is uniquely decentralized. Every component (Postgres, Nginx, Node.js, etc.) is its own self-contained package manager. 
- **Decentralized Logic:** Each module contains its own setup, lifecycle hooks, and platform-specific drivers.
- **Global Orchestration:** The global CLI (`libscript.sh` / `libscript.cmd`) acts as a routing layer that can resolve complex dependency stacks (e.g., `postgres>16,valkey,python>3.12`) and provision them in one go.

### ⚡ Pure Power, Zero Bloat
*   **Zero Dependencies:** No agents. No runtimes. Just `/bin/sh`, `.cmd`, and `.ps1`.
*   **Native Execution:** Stop paying the "container tax." Deploy high-availability clusters directly on your host OS—whether it's a FreeBSD jail, a Windows server, or a Linux box.
*   **Built-in PaaS capabilities:** LibScript automatically generates `systemd`/`launchd` service files for your apps, handles Nginx reverse proxying, and automatically fetches Let's Encrypt TLS certs—all driven by a single `libscript.json`.
*   **Truly Universal:** One codebase for 🐧 Linux, 🪟 Windows (Native CMD), 🍎 macOS, 😈 BSD, and ☀️ Solaris.
*   **Artifact Factory:** Turn your local stack into a production-ready `.msi`, `.exe` (InnoSetup/NSIS), `.deb`, `.rpm`, `.apk`, `.txz`, `.pkg`, `.dmg`, `Dockerfile`, `docker-compose.yml`, or an interactive `TUI` installer with one command: `package_as`.

---

## 🛠️ Core Capabilities

### 🏛️ Native Component Management
LibScript allows you to manage tools either through the global orchestrator or via each component's autonomous CLI.

**Using the Global Orchestrator:**
```sh
# Install and start using the top-level routing layer
./libscript.sh install nodejs 20
./libscript.sh install postgres 16
./libscript.sh start postgres
```

**Using the Local Component CLI:**
```sh
# Every component is a standalone package manager
./_lib/languages/nodejs/cli.sh install nodejs 20
./_lib/databases/postgres/cli.sh install postgres 16
./_lib/databases/postgres/cli.sh start postgres
```

### ☸️ Declarative Stack Provisioning
Define your entire infrastructure in a simple `libscript.json` and let the resolution engine handle the rest.

```json
{
  "name": "my-production-stack",
  "dependencies": {
    "nodejs": ">=20.0.0",
    "postgres": "16",
    "valkey": "latest"
  }
}
```

```sh
# Install all dependencies defined in libscript.json
./libscript.sh install-deps
```

### 🌐 Built-in PaaS & `netctl`
Stop writing boilerplate server configurations. LibScript includes `netctl`, a universal routing and proxy configuration component that turns your raw OS into a Platform-as-a-Service (PaaS). 
- **Service Management:** Automatically daemonizes your applications, generating `systemd` (Linux), `launchd` (macOS), or Windows Services.
- **Reverse Proxying:** Maps application ports to domain names, dynamically configuring Nginx or HAProxy.
- **TLS Automation:** Automatically fetches and renews Let's Encrypt certificates via Certbot for secure HTTPS routing out of the box.

### 🌍 Multicloud Mastery
Manage AWS, Azure, GCP, and DigitalOcean through a single, idempotent interface using the `provision` and `deprovision` commands. LibScript leverages native provider CLIs under the hood, securely utilizing your existing environment credentials (`~/.aws/credentials`, `gcloud auth`, etc.) without requiring external state files or agents.

```sh
# Provision a stack on AWS: <provider> <stack-name> <network> <region> <local-path> <remote-path>
./libscript.sh provision aws my-stack my-vpc us-east-1 ./ ~/my-app

# Tear down the stack and its associated resources
./libscript.sh deprovision aws my-stack us-east-1
```

### 📦 The Generator Engine
Convert your shell logic into native installers or container images instantly.

LibScript doesn't just install software—it acts as a powerful artifact factory. Using the `package_as` command, you can export your entire dependency tree, component logic, and stack configuration into a variety of distributable formats, completely automatically.

**Supported Packaging Formats:**
- **Windows Installers:** `.msi` (WiX), `.exe` (InnoSetup, NSIS)
- **Linux Packages:** `.deb` (Debian/Ubuntu), `.rpm` (RHEL/Fedora/CentOS), `.apk` (Alpine)
- **macOS/BSD Packages:** `.pkg` (macOS), `.dmg` (macOS), `.txz` (FreeBSD)
- **Containers:** `Dockerfile`, `docker-compose.yml`
- **Interactive:** `tui` (Terminal UI script)

#### How it Works

When you run `package_as`, LibScript analyzes your declarative stack configuration, traces the required `_lib` modules, and compiles them into a self-contained installer or container specification.

```sh
# Generate a Windows Installer (.msi) for your current stack
./libscript.sh package_as msi

# Generate a Dockerfile and docker-compose.yml
./libscript.sh package_as docker
./libscript.sh package_as docker-compose

# Generate a Debian package (.deb)
./libscript.sh package_as deb
```

#### Granular Dependency Control

The generator provides strict control over how your artifacts fetch and bundle dependencies via the `LIBSCRIPT_GLOBAL_INSTALL_METHOD` environment variable:

- `system`: Relies on the target OS's native package manager (e.g., `apt`, `apk`, `pacman`). This keeps artifacts tiny and leverages the OS maintainers' updates.
- `source`: Compiles tools from source or downloads static binaries. Ensures maximum isolation, reproducibility, and works on minimal base systems.

You can even define local overrides (e.g., `PYTHON_INSTALL_METHOD="uv"`) to mix and match system-provided stable packages with newer, custom-managed toolchains within the same generated artifact.

#### Smart Context Assembly

The generator engine automatically handles the assembly of file structures and configurations. For Docker, it natively resolves filesystem composition before handing off to the container daemon. This bypasses common limitations (like symbolic links failing across `Dockerfile` build contexts) without requiring you to write tedious `COPY` commands or manage context paths manually—LibScript yields a ready-to-build, fully contained directory.

---

## 🚀 Quick Start

**1. Clone the power:**
```sh
git clone https://github.com/SamuelMarks/libscript.git
cd libscript
```

**2. List everything you can build:**
```sh
./libscript.sh list
```

**3. Install a high-performance stack natively:**
```sh
./libscript.sh install nodejs 20
./libscript.sh install postgres latest
./libscript.sh start postgres
```

---

## 🏗️ Architecture: Bare Metal First

LibScript is designed as a routing execution layer. It detects your OS, maps generic dependencies to local package managers (`apt`, `brew`, `choco`, `pkg`), and executes optimized setup scripts.

*   **`cli/`**: Core CLI commands, orchestration logic, and the `package_as` transformation engine.
*   **`_lib/`**: The heart of the system. Modular components (over 140+ available) where each directory is a standalone manager.
*   **`gen/`**: Artifact generator module, synthesizing logic into installers, Docker images, and packages.
*   **`netctl/`**: Universal routing, firewall, and reverse proxy configuration component.
*   **`scripts/`**: Core system utilities for daemonization, cloud deployments, and git hook management.
*   **`stacks/`**: Pre-configured, battle-tested blueprints for CMS, ERP, Data Science, and more.
*   **`vagrant/`**: Vagrantfiles and setup scripts for testing across multiple OS targets (Alpine, Debian, FreeBSD, etc.).
*   **`dockerfiles-ssh/`**: Base container images pre-configured for SSH access and testing.

---

## 🤝 Community & Support

LibScript is built for the community. Whether you're managing a single Raspberry Pi or a global multicloud fleet, we want to hear from you.

*   **Read the Docs:** [ARCHITECTURE.md](./ARCHITECTURE.md), [USAGE.md](./USAGE.md), [WHY.md](./WHY.md)
*   **Contribute:** Check out [DEVELOPING.md](./DEVELOPING.md) to get started.

---

**LibScript: Because your infrastructure should be as fast as your code.**

---

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <https://apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <https://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall be
dual licensed as above, without any additional terms or conditions.
