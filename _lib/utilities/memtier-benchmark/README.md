# memtier-benchmark

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `memtier-benchmark`
component (part of `_utilities`) within the LibScript ecosystem. High-throughput NoSQL Redis and
Memcached traffic generator recording P50, IQR, and P99 tail latencies.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **memtier_benchmark Load
Generator**. It is designed to be executed via the global `libscript.sh` router or directly via
`cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install memtier-benchmark
libscript uninstall memtier-benchmark
```

**Start / Stop (if configured as a background service):**

```sh
libscript start memtier-benchmark
libscript stop memtier-benchmark
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker memtier-benchmark
```

_Note: On Unix environments, you can also use `./cli.sh install memtier-benchmark`. On Windows, use
`libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                | Default       | Aliases/Examples |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `MEMTIER_BENCHMARK_INSTALL_METHOD` | How to install memtier-benchmark. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `MEMTIER_BENCHMARK_VERSION`        | Specific version of memtier-benchmark to install.                                                                                                          | `2.1.1`       | latest, lts      |
| `MEMTIER_BENCHMARK_DOWNLOAD_URL`   | Override URL for downloading memtier-benchmark binary or archive artifacts.                                                                                | `none`        |                  |
| `MEMTIER_BENCHMARK_RELEASES_URL`   | Override URL for querying memtier-benchmark available remote releases.                                                                                     | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic and native version manager operations.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
