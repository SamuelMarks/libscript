# Testing

LibScript ensures reliability through a rigorous testing philosophy. Each component must be capable of verifying its own installation.

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
