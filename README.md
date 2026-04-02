🚀 LibScript: The Universal Provisioning Engine
===============================================
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
*   **Truly Universal:** One codebase for 🐧 Linux, 🪟 Windows (Native CMD), 🍎 macOS, 😈 BSD, and ☀️ Solaris.
*   **Artifact Factory:** Turn your local stack into a production-ready `.msi`, `.deb`, `.rpm`, `.apk`, or `Dockerfile` with one command: `package_as`.

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
```sh
# Install all dependencies defined in libscript.json
./libscript.sh install-deps
```

### 🌍 Multicloud Mastery
Manage AWS, Azure, and GCP through a single, idempotent interface. Provision VPCs, S3 buckets, and node groups without learning three different CLI syntaxes.
```sh
./libscript.sh cloud aws node-group create web-tier 5
```

### 📦 The Generator Engine
Convert your shell logic into native installers or container images instantly.
```sh
# Generate a Windows Installer (.msi) for your current stack
./libscript.sh package_as msi
```

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

*   **`_lib/`**: The heart of the system. Modular components where each directory is a standalone manager.
*   **`stacks/`**: Pre-configured, battle-tested blueprints for CMS, ERP, and Data Science.
*   **`package_as`**: The transformation engine that converts shell logic into native installers.

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
