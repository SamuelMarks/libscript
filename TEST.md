# Testing Strategy

## Purpose
Details how LibScript ensures idempotent, error-free execution across a massively fragmented landscape of operating systems, architectures, and shells.

## What Makes The Testing Strategy Interesting?
Because LibScript modifies the host OS natively, testing isn't just unit-testing code; it's testing state mutations on actual machines. We employ a multi-layered approach involving localized shell scripts, comprehensive CI matrices, and Vagrant VM orchestration.

## Component Verification (`test.sh` / `test.cmd`)
Every component ships with an active verification script.
- **Toolchains**: Compiles a real program (e.g., C++ compiles a binary, Node.js runs an eval).
- **Servers**: Runs configuration syntax checks (`nginx -t`) or hits health endpoints.
- **Databases**: Executes native client commands (e.g., `psql -c "SELECT 1;"`) to ensure the daemon is actively accepting connections.

## Continuous Integration (GitHub Actions)
Our `ci.yml` matrix is exhaustive. It automatically provisions pristine environments across:
- `ubuntu-latest`
- `macos-latest`
- `windows-latest`
It installs each component, executes its tests, and asserts success, guaranteeing cross-platform parity.

## Deep Vagrant Validation
For edge-case distributions (Alpine, FreeBSD, AlmaLinux), the `vagrant/` directory provides configurations to spin up ephemeral local VMs. This allows developers to mount the repository, run tests locally in a pristine shell, and destroy the environment in seconds.
