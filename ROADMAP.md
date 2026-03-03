# Roadmap

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
