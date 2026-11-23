# memtier_benchmark Load Generator (`_lib/utilities/memtier-benchmark/`)

## Overview

High-throughput NoSQL Redis and Memcached traffic generator recording P50, IQR, and P99 tail
latencies.

- **Tier**: `T1` (`_lib/utilities/memtier-benchmark/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `memtier-benchmark`, `memtier_benchmark`
- **Target OS Whitelist (`manifest.json`)**: `linux`, `darwin`, `freebsd`, `windows`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/memtier-benchmark/<version>)
./libscript.sh ls-remote memtier-benchmark
./libscript.sh install memtier-benchmark latest
./libscript.sh use memtier-benchmark latest
./libscript.sh which memtier-benchmark
./_lib/utilities/memtier-benchmark/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote memtier-benchmark
.\libscript.cmd install memtier-benchmark latest
.\libscript.cmd use memtier-benchmark latest
.\libscript.cmd which memtier-benchmark
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under
  `${LIBSCRIPT_HOME}/memtier-benchmark/<version>` (default
  `~/.libscript/memtier-benchmark/<version>`) and synchronizes `O(1)` shims in
  `${LIBSCRIPT_HOME}/bin` without polluting system paths.
- **Override Strategy**: Control installation via `MEMTIER_BENCHMARK_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

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

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
