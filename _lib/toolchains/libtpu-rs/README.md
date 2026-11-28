# libtpu-rs Clean-Room PJRT Driver & Compiler Suite (`_lib/toolchains/libtpu-rs/`)

## Overview

Clean-room Rust PJRT TPU runtime/compiler version manager (`SamuelMarks/libtpu-rs`), drop-in
`libtpu` PEP 427 wheel & shared library (`libtpu.so` / `libtpu.dylib` / `tpu.dll`) cache with GitHub
Releases + Cargo fallback, and SIGPLAN empirical evaluation harness.

- **Tier**: `T1` (`_lib/toolchains/libtpu-rs/`)
- **Repository**: `https://github.com/SamuelMarks/libtpu-rs`
- **Capabilities**: `userland-package`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/libtpu-rs/<version>)
./libscript.sh ls-remote libtpu-rs
./libscript.sh install libtpu-rs latest
./libscript.sh use libtpu-rs latest
./libscript.sh which libtpu-rs
./_lib/toolchains/libtpu-rs/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote libtpu-rs
.\libscript.cmd install libtpu-rs latest
.\libscript.cmd use libtpu-rs latest
.\libscript.cmd which libtpu-rs
```

## Installation & Isolation

- **Releases + Cargo Fallback (`libscript_native`)**: Attempts to fetch SHA-256 verified binary
  archives (`libtpu-v<ver>-<os>-<arch>.tar.gz`/`.zip`) and PEP 427 drop-in wheels
  (`libtpu-<ver>-*.whl`) from `https://github.com/SamuelMarks/libtpu-rs/releases`, falling back
  automatically to building `crates/libtpu-c-api` (`libtpu.so` / `libtpu.dylib` / `tpu.dll`) via
  Cargo and packaging the PEP 517 drop-in wheel (`scripts/maturin_backend.py`) via `uv build`.
- **Environment Exports**: Sourcing `env.sh` / `env.cmd` exports `LIBTPU_RS_DIR`, `LIBTPU_RS_SO`,
  `LIBTPU_RS_SDK_SO`, `LIBTPU_RS_WHEEL`, and `LIBTPU_RS_SO_SHA256`, and leaves `TPU_LIBRARY_PATH`
  untouched unless `LIBTPU_RS_ACTIVATE_TPU_LIBRARY_PATH=1`.

## Configuration Options

<!-- BEGIN_VARS -->

| Variable                              | Description                                                                                                                                                                                      | Default                                                       | Aliases/Examples |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------- | ---------------- |
| `LIBSCRIPT_EXPERIMENT_PROVIDER`       | Default cloud vendor for rapid experimentation (defaults to 'azure').                                                                                                                            | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_SIZE`           | Default instance size for rapid experimentation (defaults to '160-vCPU Standard_D160ads_v7').                                                                                                    | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_NODE`           | Default compute node name for rapid cloud experimentation.                                                                                                                                       | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_RG`             | Default resource group for rapid cloud experimentation.                                                                                                                                          | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_LOCATION`       | Default cloud location/region for rapid cloud experimentation.                                                                                                                                   | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_OS`             | Default VM operating system image for rapid cloud experimentation.                                                                                                                               | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_SUITE_MANIFEST` | Path to a declarative experiments/schemas/experiment-suite.schema.json manifest file executed by the experiment runner.                                                                          | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_WARMUP`         | Default number of unrecorded warmup runs executed before recorded benchmark trials (defaults to '10').                                                                                           | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_TRIALS`         | Default number of recorded fresh trials captured per benchmark cell (defaults to '200').                                                                                                         | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_SUBSUITES`      | Comma- or space-separated list of sub-suite identifiers to execute (e.g., 'E0,E1,E2,E3,E4,E5,E6,E7,E8').                                                                                         | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_OUT_DIR`        | Output directory for mechanical experiment JSON results and generated LaTeX macros.                                                                                                              | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_REPO_DIR`       | Local or synced remote filesystem path to the target repository under benchmark evaluation.                                                                                                      | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_PAPER_DIR`      | Local or synced remote filesystem path to the paper manuscript directory receiving generated LaTeX metrics.                                                                                      | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_ECOSYSTEM_ROOT` | Root directory containing multi-repository subject checkouts evaluated across ecosystem benchmarks.                                                                                              | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_LOCKFILE_DIR`   | Directory containing pinned provenance lockfiles (e.g., c_upstreams.lock.json and batch_wild_corpus.lock.json).                                                                                  | `none`                                                        |                  |
| `LIBSCRIPT_EXPERIMENT_EMULATION_MODE` | Controlled execution or baseline isolation mode ('native_only', 'wine_warm', 'wine_cold', 'wsl2_loopback', 'wsl2_cross_boundary', 'wsl2_cli_spawn', 'cygwin', 'msys2', or 'dos32_vagrant_com1'). | `none`                                                        |                  |
| `LIBSCRIPT_BENCH_PREPARE_HOST`        | Flag (0 or 1) to lock CPU frequency scaling governor to performance, disable ASLR, and disable swap before running compiler benchmarks.                                                          | `none`                                                        |                  |
| `LIBSCRIPT_BENCH_DROP_CACHES`         | Flag (0 or 1) to flush filesystem buffers and drop OS page caches before each compiler benchmark run.                                                                                            | `none`                                                        |                  |
| `LIBSCRIPT_BENCH_REQUIRE_NATIVE_ISA`  | Flag (0 or 1) enforcing native hardware ISA execution and rejecting Rosetta 2, QEMU, or WoW64 binary translation.                                                                                | `none`                                                        |                  |
| `LIBSCRIPT_BENCH_CARGO_PROFILE`       | Pinned Cargo release profile specification ('opt3-lto-thin-cgu1' or custom key=value list) enforced across Rust benchmarks.                                                                      | `none`                                                        |                  |
| `LIBSCRIPT_BENCH_MSVC_CRT`            | MSVC C Runtime linkage variant ('MT' for static CRT or 'MD' for dynamic CRT) applied during Windows benchmark builds.                                                                            | `none`                                                        |                  |
| `LIBSCRIPT_BENCH_WINE_MODE`           | WINE baseline execution policy ('warm' for persistent wineserver -p or 'cold' for per-trial wineserver -k).                                                                                      | `none`                                                        |                  |
| `LIBTPU_RS_INSTALL_METHOD`            | How to install libtpu-rs. 'libscript_native' downloads verified GitHub Releases with Cargo fallback, 'system' uses OS package manager, and 'from-source' compiles from Cargo source.             | `libscript_native`                                            |                  |
| `LIBTPU_RS_VERSION`                   | Specific version of libtpu-rs to install.                                                                                                                                                        | `0.0.52`                                                      | latest, lts      |
| `LIBTPU_RS_DOWNLOAD_URL`              | Override URL for downloading libtpu-rs binary or archive artifacts.                                                                                                                              | `none`                                                        |                  |
| `LIBTPU_RS_RELEASES_URL`              | Override URL for querying libtpu-rs available remote GitHub releases.                                                                                                                            | `https://api.github.com/repos/SamuelMarks/libtpu-rs/releases` |                  |
| `LIBTPU_RS_REPO_DIR`                  | Local filesystem path to the libtpu-rs workspace repository.                                                                                                                                     | `none`                                                        |                  |
| `LIBTPU_RS_GIT_URL`                   | Git URL cloned when LIBTPU_RS_REPO_DIR is not already present on disk.                                                                                                                           | `https://github.com/SamuelMarks/libtpu-rs.git`                |                  |
| `LIBTPU_RS_SO_PATH`                   | Explicit override path to a prebuilt libtpu-rs shared library (libtpu.so, libtpu.dylib, or tpu.dll).                                                                                             | `none`                                                        |                  |
| `LIBTPU_RS_SDK_SO_PATH`               | Explicit override path to a prebuilt libtpu-rs Python SDK extension library (sdk.so, sdk.dylib, or sdk.dll).                                                                                     | `none`                                                        |                  |
| `LIBTPU_RS_WHEEL_PATH`                | Explicit override path to a prebuilt drop-in PEP 427 libtpu wheel produced by libtpu-rs.                                                                                                         | `none`                                                        |                  |
| `LIBTPU_RS_DIR`                       | Resolved versioned installation directory containing libtpu-rs shared libraries and wheels.                                                                                                      | `none`                                                        |                  |
| `LIBTPU_RS_SO`                        | Resolved path to the active host-matching libtpu-rs PJRT C-API shared library (libtpu.so, libtpu.dylib, or tpu.dll).                                                                             | `none`                                                        |                  |
| `LIBTPU_RS_SDK_SO`                    | Resolved path to the active host-matching libtpu-rs SDK extension shared library.                                                                                                                | `none`                                                        |                  |
| `LIBTPU_RS_WHEEL`                     | Resolved path to the cached drop-in PEP 427 libtpu wheel (.whl) built or downloaded for libtpu-rs.                                                                                               | `none`                                                        |                  |
| `LIBTPU_RS_SO_SHA256`                 | Lowercase hexadecimal SHA-256 digest of the installed libtpu-rs PJRT shared library.                                                                                                             | `none`                                                        |                  |
| `LIBTPU_RS_ACTIVATE_TPU_LIBRARY_PATH` | Flag (0 or 1) controlling whether env.sh/env.cmd exports TPU_LIBRARY_PATH pointing at LIBTPU_RS_SO.                                                                                              | `0`                                                           |                  |
| `LIBTPU_RS_PAPER_DIR`                 | Local filesystem path to the libtpu_paper manuscript directory.                                                                                                                                  | `none`                                                        |                  |
| `LIBTPU_RS_RESULTS_DIR`               | Directory where mechanical E0-E9 JSON artifacts and generated_metrics.tex are emitted.                                                                                                           | `none`                                                        |                  |
| `LIBTPU_RS_CARGO_PROFILE`             | Pinned Cargo release profile identifier enforced under SIGPLAN RULE-6.                                                                                                                           | `opt3-lto-thin-cgu1`                                          |                  |
| `LIBTPU_RS_SLIM_FEATURES`             | Cargo feature flags passed when building the slim shared library variant without embedded reflection/CSR catalogs.                                                                               | `--no-default-features`                                       |                  |
| `LIBTPU_RS_JAX_VERSION`               | Upstream jax and jaxlib version installed into the isolated component virtual environment for Suite E3.                                                                                          | `0.4.38`                                                      |                  |
| `LIBTPU_RS_WARMUP`                    | Number of unrecorded warmup runs executed prior to recorded trials.                                                                                                                              | `10`                                                          |                  |
| `LIBTPU_RS_TRIALS`                    | Number of recorded fresh trials executed per benchmark cell.                                                                                                                                     | `200`                                                         |                  |
| `LIBTPU_RS_SUBSUITES`                 | Comma-separated list of libtpu_paper empirical sub-suites to execute.                                                                                                                            | `E0,E1,E2,E3,E4,E5,E6,E7,E8`                                  |                  |
| `LIBTPU_RS_BUILD_PDF`                 | Flag (0 or 1) enabling full pdflatex + bibtex compilation and Overfull/Type-3 PK log verification in Suite E8.                                                                                   | `0`                                                           |                  |
| `LIBTPU_RS_SYNTHETIC_FIXTURES`        | Internal CI test flag (0 or 1) enabling deterministic synthetic repository/manuscript fixtures for smoke testing without hardware or external repos.                                             | `0`                                                           |                  |
| `LIBTPU_RS_DRY_RUN`                   | Flag (0 or 1) logging planned benchmark actions and verifying prerequisites without executing heavy workloads.                                                                                   | `0`                                                           |                  |
| `LIBTPU_RS_HOST_ARCH`                 | Canonical OS/ISA identifier ('linux_x64', 'macos_arm64', or 'windows_x64') tagged onto per-host benchmark artifacts.                                                                             | `none`                                                        |                  |
| `LIBTPU_RS_ALLOW_DIRTY`               | Flag (0 or 1) permitting exploratory local development runs on dirty git worktrees prior to final RULE-1 locking.                                                                                | `0`                                                           |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
