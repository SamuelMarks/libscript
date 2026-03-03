# Testing

## Purpose & Current State

**Purpose**: This document explains the LibScript testing strategy, covering local verification scripts (`test.sh`/`test.cmd`), continuous integration (GitHub Actions), and Vagrant VM setups. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## Component Verification (`test.sh` and `test.cmd`)

Every component contains a `test.sh` (and `test.cmd` for Windows) that performs an active check.

- **Toolchains:** These tests do more than check `--version`. They generate a "Hello World" source file, compile it, run the executable, and assert standard output.
- **Servers:** Web servers (like Nginx) run configuration syntax checks (`nginx -t`).
- **Storage/Databases:** Databases run a client connection and execute a ping or query (e.g., `psql -c "SELECT 1;"` or `redis-cli PING`).

### Running Tests Locally

You can run the test script for any component manually:
```sh
./libscript.sh test rust
```

To run all tests across the repository, use a find command:
```sh
find . -name "test.sh" -exec {} \;
```

## Continuous Integration (CI)

We utilize GitHub Actions (`.github/workflows/ci.yml`) to automatically test components across multiple operating systems.

The CI Matrix covers:
- **Operating Systems:** `ubuntu-latest`, `macos-latest`, `windows-latest`.
- **Components:** Every toolchain, server, and storage component in `_lib/` and `app/`.

If a component is inherently incompatible with a specific OS (e.g., `kubernetes_k0s` on Windows), it is specifically excluded in the CI matrix configuration.

## Vagrant Integration

For deeper, multi-distribution local testing (Debian, AlmaLinux, Alpine, FreeBSD), the `vagrant/` directory provides configurations to spin up ephemeral VMs, mount the `libscript` repository, and run installation scripts in pristine environments.
