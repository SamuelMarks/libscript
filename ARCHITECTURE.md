# Architecture

## Purpose
This document details the internal directory structure, execution lifecycle, and core abstractions (`os_info.sh`, `pkg_mgr.sh`) that power LibScript's zero-dependency, cross-platform provisioning engine.

## What Makes This Architecture Interesting?
LibScript eschews heavyweight agents and runtimes (like Python for Ansible or Go for Terraform) in favor of a strictly POSIX `sh` and Windows `cmd` routing layer. This architecture allows a component to define its schema via JSON (`vars.schema.json`), which the global router (`libscript.sh` / `libscript.cmd`) dynamically parses to generate CLI help text, parse arguments, generate environment variables, and compile advanced deployment artifacts (like MSIs or Dockerfiles).

## Core Structure
The repository is split into modular components:
- `_lib/_toolchain/`: Compilers, interpreters, and CLI tools.
- `_lib/_server/`: Web servers, proxies, and container runtimes.
- `_lib/_storage/`: Databases, caches, and message queues.
- `app/`: High-level third-party application stacks.

Each component contains:
- `cli.sh` / `cli.cmd`: Entrypoint that parses options against `vars.schema.json`.
- `setup.sh` / `setup.cmd` / `setup_win.ps1`: The actual installation and configuration logic.
- `test.sh` / `test.cmd`: Idempotent verification tests.
- `vars.schema.json`: Configuration schema (ports, passwords, versions).

## Execution Lifecycle
1. **Invocation**: The user runs `./libscript.sh install <pkg> <version> [args]`.
2. **Routing**: The global CLI locates the package and executes its `cli.sh`.
3. **Configuration**: `cli.sh` maps CLI arguments to exported environment variables (e.g., `--PORT=8080` becomes `export LIBSCRIPT_GLOBAL_PORT=8080`).
4. **Environment Detection**: `setup.sh` sources `os_info.sh` to determine `TARGET_OS`, `TARGET_ARCH`, and the init system (Systemd/OpenRC).
5. **Dependency Resolution**: `pkg_mgr.sh` maps and installs native OS requirements via the native package manager.
6. **Installation**: Binaries are downloaded, cached, extracted to the `--prefix`, and configured.
7. **Service Registration**: If applicable, the component registers a background daemon natively.

## The Generator Layer (`package_as`)
A standout architectural feature is the global CLI's ability to introspect components. By parsing the component schemas and utilizing the declarative `env` output, LibScript can synthesize standard installers (DEB, RPM, APK), Windows installers (WiX, InnoSetup, NSIS), Dockerfiles, and `docker-compose.yml` configurations on the fly without running the actual installation locally.
