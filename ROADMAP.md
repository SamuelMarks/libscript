# Roadmap

## Purpose
Tracks the phased delivery of LibScript's capabilities from its foundational release to its ultimate form as a universal orchestrator.

## What Makes This Roadmap Interesting?
It tracks the evolution from a simple script collection into a fully declarative, cross-compiling, multi-platform orchestrator capable of generating deployment artifacts (Docker, MSI, DEB) dynamically from its own runtime context.

## Phase 1: Foundation (Completed)
- [x] Zero-dependency shell execution framework.
- [x] Package manager abstraction (`pkg_mgr.sh`).
- [x] Vast component library (Rust, Python, Node, Postgres, Nginx).
- [x] Verification scripts and CI Matrix.

## Phase 2: Windows & Declarative Parity (Completed)
- [x] Full MS-DOS (`.bat`), Windows Command (`.cmd`), and PowerShell (`.ps1`) support.
- [x] Component-level CLI routing and JSON schema validation.
- [x] Declarative installations via `libscript.json` (`install-deps`).

## Phase 3: The Generator Engine (Current)
- [x] `package_as docker` / `docker_compose` generator.
- [x] `package_as` Windows Installers (MSI via WiX, InnoSetup, NSIS).
- [x] `package_as` Native Packages (DEB, RPM, APK).
- [ ] Stabilize dynamic configuration injection (passing generated database credentials directly to dependent application layers).

## Phase 4: Advanced Orchestration (Next)
- [ ] Concurrent DAG-based execution for `libscript.json`.
- [ ] Full uninstall and state-rollback lifecycle.
- [ ] Rewrite the top-level router in Rust/Go for speed, keeping scripts for execution.
