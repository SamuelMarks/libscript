# Architecture: Decentralized & Native

LibScript is a framework for cross-platform software provisioning and packaging, built on zero-dependency shell scripts. Its architecture follows a **Decentralized Routing** model: the global engine routes requests to autonomous, component-specific package managers.

## 🏛️ The "Every-Thing-is-a-Package-Manager" Philosophy

Unlike monolithic configuration managers that rely on a central state and heavy runtimes, LibScript treats every component (Postgres, Redis, Python, etc.) as a first-class, self-contained package manager.

- **Autonomy:** Each module in `_lib/` contains its own logic for installation, service management, and uninstallation. They are "smart" components that understand their own lifecycle.
- **Isolation:** Components are designed to be "aware" of their own dependencies but managed independently, allowing for granular version control and side-by-side installations of different versions without global system side effects.
- **Routing Layer:** The global CLI (`libscript.sh` / `libscript.cmd`) acts as a high-speed, zero-dependency router. When you run `./libscript.sh install postgres`, the global engine locates the `postgres` module and hands off execution to its local `cli.sh`.

## 🔀 Cross-Platform Parity

A core mandate of LibScript is native execution without heavy runtimes. We achieve this through strict parity between POSIX and Windows scripts:

- **POSIX Systems (Linux, macOS, BSD, Solaris):** Powered by `/bin/sh`. We avoid "bash-isms" to ensure compatibility with minimalist shells like `dash` or `ash` found in Alpine or embedded systems.
- **Windows Systems:** Powered by native `.cmd` (Command Prompt) and `.ps1` (PowerShell). No WSL, Cygwin, or MSYS2 is required for the core engine to function.
- **Unified Semantics:** Whether you are on Windows or Linux, the command structure (`install`, `start`, `stop`, `env`) remains identical, providing a consistent operational experience across the entire fleet.

## 📦 Component Modules

Each component in `_lib/` is structured to be a standalone manager:
- `vars.schema.json`: Strictly typed metadata, default ports, and dependency definitions.
- `cli.sh` / `cli.cmd`: The platform-specific entry points that handle command routing.
- `setup.sh` / `setup_win.ps1`: The "guts" of the installation logic.
- `manifest.json`: Defines the component's capabilities (e.g., provides `database`, conflicts with `mysql`).

## ☸️ The Global Resolution Engine

LibScript includes a built-in automated stack resolution engine implemented in `jq`. This engine:
1.  Reads a declarative `libscript.json` stack definition.
2.  Traverses the `_lib/` directory to collect component manifests.
3.  Resolves version constraints (e.g., `postgres>=16`, `python~=3.10`) and transitive dependencies.
4.  Generates an optimized execution plan for either native installation or container generation.

## ☁️ PaaS Orchestration Layer

The `cloud` component (`_lib/cloud`) provides a unified, multicloud PaaS interface. It delegates to provider-specific modules in `_lib/cloud-providers/`, wrapping official vendor CLIs (`aws`, `az`, `gcloud`) into a consistent, idempotent syntax for managing compute, network, and storage.

## 🛠️ The Generator Engine (`package_as`)

LibScript uses component metadata to translate native definitions into various production artifacts:
- **Containers:** Optimized `Dockerfile` and `docker-compose.yml` manifests.
- **Native Installers:** MSI and EXE via InnoSetup/NSIS (Windows), DEB/RPM/APK (Linux), TXZ (FreeBSD), and PKG/DMG (macOS).
- **Interactive Shell:** A `TUI` installer using `dialog`/`whiptail` to select components and generate targets.
