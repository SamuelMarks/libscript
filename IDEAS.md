# Future Ideas & Feature Roadmap

This document serves as a prioritized roadmap for experimental features, architectural improvements, and new components for LibScript. It bridges the gap between raw ideas and actionable development phases.

## 1. Advanced Local Testing Orchestration (Vagrant)

While GitHub Actions provides an excellent CI baseline across major OS runners (Ubuntu, macOS, Windows), deep validation across diverse Linux distributions and BSDs requires a robust local testing suite.

**The Vagrant Vision:**
- **Multi-Distro Matrix:** Utilize the existing configurations in the `vagrant/` directory to orchestrate ephemeral VMs for Alpine, AlmaLinux, Debian, FreeBSD, and older OS variants.
- **Synced Execution:** Mount the local `libscript` repository as a synced folder inside the VMs. This allows developers to test local script changes instantly without committing or pushing code.
- **Automated Test Harness:** Develop a master script (e.g., `vagrant/run_all_tests.sh`) that programmatically iterates through all configured VMs, runs `vagrant up`, executes the full `libscript.sh` test suite (invoking `<COMMAND>` for every component), aggregates the success/failure results, and then safely destroys the VMs (`vagrant destroy -f`).
- **Offline Validation:** Ensure the framework can be tested in low-bandwidth environments by heavily utilizing cached Vagrant boxes.

## 2. Architectural & Core Improvements

- **Uninstall & Cleanup Lifecycle:** Introduce `uninstall.sh` and `uninstall.cmd` for all components. This will allow LibScript to cleanly remove binaries, purge injected configuration blocks, and unregister systemd/OpenRC/Windows services.
- **State Rollbacks:** Implement a mechanism to snapshot system state (e.g., backing up modified config files to `/tmp`) prior to installation, allowing for automatic rollback if a component's `setup.sh` or `test.sh` fails.
- **Interactive TUI (Terminal User Interface):** Build a `dialog` or `whiptail`-based frontend for users to interactively select components (via checkboxes) and input configuration variables, which then automatically generates an `install.json`.
- **Parallel Execution Graph:** Enhance the `install.json` parser to build a dependency graph and install non-blocking components concurrently. This would significantly speed up the bootstrapping of complex multi-component environments.
- **Compiled CLI Wrapper:** Eventually rewrite the top-level `libscript` router in Rust or Go to provide faster argument parsing, schema validation, and parallel execution management, while strictly preserving the underlying `.sh` and `.cmd` scripts for the actual execution logic.

## 3. Component Expansion Roadmap

### Phase A: Core Languages & Runtimes
Expanding the `_lib/_toolchain/` ecosystem to cover more modern and niche languages.
- `zig`
- `elixir` / `erlang`
- `haskell` (via `ghcup`)
- `nim`
- `dart` (and potentially the Flutter SDK)

### Phase B: Databases & Storage
Expanding `_lib/_storage/` for comprehensive backend support.
- `mysql` / `mariadb`
- `mongodb`
- `sqlite3` (CLI tools and dev headers)
- `clickhouse`

### Phase C: Infrastructure, Containers & Web Servers
Expanding `_lib/_server/` and container orchestration.
- `caddy` (as an auto-HTTPS alternative to Nginx)
- `traefik`
- `haproxy`
- `docker` & `docker-compose` (System-level installation)
- `podman`
