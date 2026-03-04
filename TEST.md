# Testing

## Purpose & Current State

**Purpose**: This document explains the LibScript testing strategy, covering local verification scripts (`test.sh`/`test.cmd`), continuous integration (GitHub Actions), and Vagrant VM setups. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: The testing strategy is actively enforced via GitHub Actions across Ubuntu, macOS, and Windows runners. Components utilize localized `test.sh` and `test.cmd` scripts for behavioral verification. Vagrant VM configurations are available for deeper multi-distro validation, though fully automated local VM orchestration remains in development.

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
