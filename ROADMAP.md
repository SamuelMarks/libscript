# Development Roadmap

This document outlines the current and historical development phases of the LibScript framework.

## Phase 1: The Native Engine (Completed)
- Developed the cross-platform, zero-dependency shell execution core.
- Established a standard library of toolchains and server components (e.g., Node, Rust, Postgres, Nginx).
- Implemented dependency resolution for declarative stack building.

## Phase 2: The Generator Layer (Completed)
- Introduced the `package_as` interface to generate Dockerfiles and Docker Compose configurations from component schemas.
- Added dynamic compilation of native installers for Windows (MSI, InnoSetup, NSIS), Linux (DEB, RPM, APK), FreeBSD (TXZ), and macOS (PKG, DMG).
- Validated integration workflows with external configuration management tools.

## Phase 3: Total Platform Parity (Current)
- **Concurrent DAG Execution:** Implementing parallel processing for the native stack provisioning graph.
- **Interactive Builders:** Finalizing a Terminal UI (TUI) for interactive stack design and compilation.
- **Extended Platform Support:** Expanding native package generation for OpenBSD and Illumos ecosystems.
