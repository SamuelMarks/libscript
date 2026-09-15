# LibScript Test Suite

This directory contains automated cross-platform test runners, batch execution harnesses, and
validation suites for LibScript components and stacks.

## Test Runners

- **`run_native_tests.*`**: Executes test suites directly on the native host environment across
  specified categories or components without requiring Vagrant or virtual machines.
  - POSIX Shell: `tests/run_native_tests.sh`
  - Windows Command Prompt: `tests\run_native_tests.cmd`
  - PowerShell: `tests\run_native_tests.ps1`
- **`run_local_tests.*`**: Executes test suites locally inside isolated Vagrant virtual machines
  across supported guest operating systems (Alpine 3.24, Debian 13, FreeBSD 15.1, Rocky Linux 10.2).
- **`run_all_batches.*`**: Executes all test batches sequentially across components.
- **`run_next_batch.*`**: Incremental batch test executor for CI environments.
- **`update_results.*`**: Aggregates test results (`*.success`, `*.failure`) from `tests_tmp/`,
  updates the Supported Components compatibility matrix in `README.md`, updates completed items in
  `TODO_PLAN.md`, and optionally exports a JSON results matrix.

## Running Native Tests

To test components directly on your current machine or CI runner:

POSIX (`/bin/sh`):

```sh
# Run tests for specific components
./tests/run_native_tests.sh sqlite curl

# Run tests for a category
./tests/run_native_tests.sh --category databases

# Run dry-run simulation
./tests/run_native_tests.sh --dry-run sqlite
```

Windows (`cmd.exe`):

```cmd
:: Run tests for specific components
call tests\run_native_tests.cmd sqlite curl

:: Run tests for a category
call tests\run_native_tests.cmd --category databases

:: Run dry-run simulation
call tests\run_native_tests.cmd --dry-run sqlite
```

````

## Running Isolated Vagrant Tests

Run local Vagrant test suites across guest distributions:

```sh
# Default: Alpine Linux 3.24
./tests/run_local_tests.sh sqlite

# Specific target OS
./tests/run_local_tests.sh sqlite --os debian-13
./tests/run_local_tests.sh sqlite --os freebsd-15.1
./tests/run_local_tests.sh sqlite --os rockylinux-10.2
````

## Central Results Reporting

Aggregate test output artifacts and update the root `README.md` compatibility table:

```sh
# Update root README.md
./tests/update_results.sh

# Update a custom report file and export JSON matrix
./tests/update_results.sh --output REPORT.md --json tests_tmp/matrix_results.json
```

Windows equivalent:

```cmd
call tests\update_results.cmd --output REPORT.md --json tests_tmp\matrix_results.json
```

## Artifact Naming Conventions

All test outputs and status markers are stored in `tests_tmp/`:

| Artifact                       | Purpose                                                    |
| ------------------------------ | ---------------------------------------------------------- |
| `<component>.<os_tag>.stdout`  | Standard output stream from `install` and `test` execution |
| `<component>.<os_tag>.stderr`  | Standard error stream from `install` and `test` execution  |
| `<component>.<os_tag>.success` | Marker file created upon zero exit code                    |
| `<component>.<os_tag>.failure` | Marker file created upon non-zero exit code                |

Supported `<os_tag>` values include `linux.alpine`, `linux.debian`, `linux.rhel`, `freebsd`, and
`windows`.
