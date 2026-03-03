# Documentation Roadmap

## Purpose & Current State

**Purpose**: This document outlines current documentation gaps and the future plan to standardize component-level READMEs, build a static site, and provide practical examples. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## Current State
- Root markdown files (`README.md`, `ARCHITECTURE.md`, `DEVELOPING.md`, `USAGE.md`, `DEPENDENCIES.md`, `TEST.md`, `WINDOWS.md`) provide a comprehensive overview.
- Component-level `README.md` files exist but are sparse.

## Next Steps

1. **Component Documentation Consistency:**
   - Every directory in `_lib/` and `app/` needs a standardized `README.md` explaining what it installs, the configuration options (`vars.schema.json`), and any OS-specific caveats.
   - Script a generator that converts `vars.schema.json` into markdown tables for the component READMEs.

2. **Examples Repository:**
   - Create a `examples/` directory containing complete `install.json` manifests for common setups (e.g., "LEMP stack", "Data Science Workspace", "Rust Web Backend").

3. **Inline Script Documentation:**
   - Add detailed comments to the core functions in `_lib/_common/` (e.g., `pkg_mgr.sh`, `os_info.sh`) explaining the parameters and expected returns.

4. **Static Site:**
   - Compile the markdown files using MkDocs or Docusaurus and host them on GitHub Pages.
