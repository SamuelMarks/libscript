# Roadmap

## Purpose & Current State

**Purpose**: This document tracks the project's long-term goals in phased milestones, from foundational architecture and Windows parity to advanced orchestration capabilities. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## Phase 1: Foundation (Complete)
- [x] Base architecture established (`cli.sh`, `setup.sh`, `env.sh`).
- [x] Package manager abstraction (`pkg_mgr.sh`, `pkg_mapper.sh`).
- [x] Core toolchains (Rust, Python, Node, Go, Java, C/C++).
- [x] Core servers and databases (Postgres, Nginx, Valkey).
- [x] Verification scripts (`test.sh`, `test.cmd`).
- [x] GitHub Actions CI Matrix.

## Phase 2: Windows Parity (In Progress)
- [x] Root `libscript.cmd` router.
- [x] Component-level `cli.cmd` scaffolding.
- [x] Windows verification scripts (`test.cmd`).
- [ ] Implement robust `setup_win.ps1` scripts for all toolchains.
- [ ] Implement Windows Service registration for databases.

## Phase 3: Advanced Orchestration
- [ ] Fully functional `install.json` processor with dependency resolution.
- [ ] Parallel execution of component installations.
- [ ] Deep integration with Vagrant for automated cross-distribution regression testing.
- [ ] Formal `libscript` CLI binary (written in Rust or Go) to replace the shell-script router for improved performance and UX, while maintaining shell scripts for the actual setup logic.

## Phase 4: Application Ecosystem
- [ ] Add more heavy-weight applications to `app/third_party/`.
- [ ] Standardize the configuration injection for applications (e.g., passing DB credentials from the Postgres component into the application component automatically).
