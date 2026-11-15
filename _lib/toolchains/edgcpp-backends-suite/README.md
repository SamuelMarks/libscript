# edgcpp-backends-suite

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `edgcpp-backends-suite`
component (part of `_toolchains`) within the LibScript ecosystem. Declarative zero-hallucination
benchmarking suite (E0-E7) evaluating EDG C/C++ v7.0.1 LLVM, GCC/libgccjit, and legacy backends
across latency, SQLite ablations, EH, C++20 coroutines, psABI/Csmith/YARPGen fuzzing,
open-source/Linux kernel corpora, and 60-placeholder LaTeX synthesis.

## Usage

_Note: libscript manages versions natively for this component._

This directory contains the installation and configuration scripts for **EDG C/C++ Multi-Backend
Empirical Evaluation Suite (E0-E7)**. It is designed to be executed via the global `libscript.sh`
router or directly via `cli.sh`.

### Lifecycle & Usage

**Install / Uninstall:**

```sh
libscript install edgcpp-backends-suite
libscript uninstall edgcpp-backends-suite
```

**Start / Stop (if configured as a background service):**

```sh
libscript start edgcpp-backends-suite
libscript stop edgcpp-backends-suite
```

**Package (e.g., as a Docker container):**

```sh
libscript package-as docker edgcpp-backends-suite
```

_Note: On Unix environments, you can also use `./cli.sh install edgcpp-backends-suite`. On Windows,
use `libscript.cmd` or `cli.cmd`._

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                               | Description                                                                                                                                                                                      | Default            | Aliases/Examples |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------ | ---------------- |
| `LIBSCRIPT_EXPERIMENT_PROVIDER`        | Default cloud vendor for rapid experimentation (defaults to 'azure').                                                                                                                            | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_SIZE`            | Default instance size for rapid experimentation (defaults to '160-vCPU Standard_D160ads_v7').                                                                                                    | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_NODE`            | Default compute node name for rapid cloud experimentation.                                                                                                                                       | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_RG`              | Default resource group for rapid cloud experimentation.                                                                                                                                          | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_LOCATION`        | Default cloud location/region for rapid cloud experimentation.                                                                                                                                   | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_OS`              | Default VM operating system image for rapid cloud experimentation.                                                                                                                               | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_SUITE_MANIFEST`  | Path to a declarative experiment-suite.schema.json manifest file executed by the experiment runner.                                                                                              | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_WARMUP`          | Default number of unrecorded warmup runs executed before recorded benchmark trials (defaults to '10').                                                                                           | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_TRIALS`          | Default number of recorded fresh trials captured per benchmark cell (defaults to '200').                                                                                                         | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_SUBSUITES`       | Comma- or space-separated list of sub-suite identifiers to execute (e.g., 'E0,E1,E2,E3,E4,E5,E6,E7,E8').                                                                                         | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_OUT_DIR`         | Output directory for mechanical experiment JSON results and generated LaTeX macros.                                                                                                              | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_REPO_DIR`        | Local or synced remote filesystem path to the target repository under benchmark evaluation.                                                                                                      | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_PAPER_DIR`       | Local or synced remote filesystem path to the paper manuscript directory receiving generated LaTeX metrics.                                                                                      | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_ECOSYSTEM_ROOT`  | Root directory containing multi-repository subject checkouts evaluated across ecosystem benchmarks.                                                                                              | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_LOCKFILE_DIR`    | Directory containing pinned provenance lockfiles (e.g., c_upstreams.lock.json and batch_wild_corpus.lock.json).                                                                                  | `none`             |                  |
| `LIBSCRIPT_EXPERIMENT_EMULATION_MODE`  | Controlled execution or baseline isolation mode ('native_only', 'wine_warm', 'wine_cold', 'wsl2_loopback', 'wsl2_cross_boundary', 'wsl2_cli_spawn', 'cygwin', 'msys2', or 'dos32_vagrant_com1'). | `none`             |                  |
| `LIBSCRIPT_BENCH_PREPARE_HOST`         | Flag (0 or 1) to lock CPU frequency scaling governor to performance, disable ASLR, and disable swap before running compiler benchmarks.                                                          | `none`             |                  |
| `LIBSCRIPT_BENCH_DROP_CACHES`          | Flag (0 or 1) to flush filesystem buffers and drop OS page caches before each compiler benchmark run.                                                                                            | `none`             |                  |
| `LIBSCRIPT_BENCH_REQUIRE_NATIVE_ISA`   | Flag (0 or 1) enforcing native hardware ISA execution and rejecting Rosetta 2, QEMU, or WoW64 binary translation.                                                                                | `none`             |                  |
| `LIBSCRIPT_BENCH_CARGO_PROFILE`        | Pinned Cargo release profile specification ('opt3-lto-thin-cgu1' or custom key=value list) enforced across Rust benchmarks.                                                                      | `none`             |                  |
| `LIBSCRIPT_BENCH_MSVC_CRT`             | MSVC C Runtime linkage variant ('MT' for static CRT or 'MD' for dynamic CRT) applied during Windows benchmark builds.                                                                            | `none`             |                  |
| `LIBSCRIPT_BENCH_WINE_MODE`            | WINE baseline execution policy ('warm' for persistent wineserver -p or 'cold' for per-trial wineserver -k).                                                                                      | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_INSTALL_METHOD` | How to install edgcpp-backends-suite. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source.                                   | `libscript_native` |                  |
| `EDGCPP_BACKENDS_SUITE_VERSION`        | Specific version of edgcpp-backends-suite to install.                                                                                                                                            | `1.0.0`            | latest, lts      |
| `EDGCPP_BACKENDS_SUITE_DOWNLOAD_URL`   | Override URL for downloading edgcpp-backends-suite binary or archive artifacts.                                                                                                                  | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_RELEASES_URL`   | Override URL for querying edgcpp-backends-suite available remote releases.                                                                                                                       | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_REPO`           | Pinned filesystem checkout of edgcpp-compiler-multibackend evaluated by E0-E7.                                                                                                                   | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_PAPER_DIR`      | Manuscript directory containing edgecpp_backends.tex and scripts/render_tex_tables.py.                                                                                                           | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_RESULTS_DIR`    | Output directory receiving results/raw/*.json and generated_metrics.tex.                                                                                                                         | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_SYNTHETIC`      | When true, executes deterministic synthetic fixture mode for fast offline CI and self-test verification.                                                                                         | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_TRIALS`         | Number of timed benchmark iterations per compiler pipeline cell (after 1 untimed warmup run).                                                                                                    | `11`               |                  |
| `EDGCPP_BACKENDS_SUITE_WARMUPS`        | Number of untimed warmup runs executed prior to recorded timed iterations.                                                                                                                       | `1`                |                  |
| `EDGCPP_BACKENDS_SUITE_SUBSUITES`      | Comma-separated list of sub-suites to run (default 'E0,E1,E2,E3,E4,E5,E6,E7').                                                                                                                   | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_HOST_ARCH`      | Canonical host OS/ISA identifier recorded in benchmark outputs (e.g., macos_arm64, linux_x64, windows_x64).                                                                                      | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_BUILD_PDF`      | When set to '1', compiles edgecpp_backends.tex via texlive and verifies zero Overfull boxes and <= 20 main-text pages.                                                                           | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_CROSS_ISA_QEMU` | When set to '1' on Linux, runs the optional 6-architecture Cross-ISA qemu-user-static psABI interop fuzz sweep in E5.                                                                            | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_ALLOW_DIRTY`    | Override flag ('1') allowing local development runs on uncommitted repositories without failing RULE-1.                                                                                          | `none`             |                  |
| `EDGCPP_BACKENDS_SUITE_DRY_RUN`        | When set to '1', validates manifests and command routing without executing long compiler sweeps.                                                                                                 | `none`             |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `_lib/_common/README.md`.
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
