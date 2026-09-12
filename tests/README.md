# LibScript Test Suite

This directory contains automated cross-platform test runners, batch execution harnesses, and
validation suites for LibScript components and stacks.

## Test Runners

- **`run_local_tests.*`**: Executes test suites locally inside Vagrant virtual machines across
  supported guest operating systems (Alpine, Debian, AlmaLinux, FreeBSD).
- **`run_all_batches.*`**: Executes all test batches sequentially across components.
- **`run_next_batch.*`**: Incremental batch test executor for CI environments.
- **`update_results.*`**: Aggregates test pass/fail results and updates the compatibility matrix in
  the root `README.md`.

## Running Tests

Run the full local test suite via:

```sh
./tests/run_local_tests.sh
```

Or execute component-specific tests directly:

```sh
./libscript.sh test <component> [version]
```
