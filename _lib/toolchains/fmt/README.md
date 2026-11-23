# {fmt} Modern C++17 Formatting Library (`_lib/toolchains/fmt/`)

## Overview

Standalone version manager and CMake source builder for {fmt} (pinned default 11.0.2), providing
both single-TU fmt/format.cc template inputs and full multi-TU CTest verification.

- **Tier**: `T1` (`_lib/toolchains/fmt/`)
- **Capabilities**: `userland-package`
- **Provides Virtual Capabilities**: `fmt`, `libfmt`

## Usage

```sh
# Native version management (isolated under ${LIBSCRIPT_HOME}/fmt/<version>)
./libscript.sh ls-remote fmt
./libscript.sh install fmt latest
./libscript.sh use fmt latest
./libscript.sh which fmt
./_lib/toolchains/fmt/cli.sh test
```

```cmd
:: Windows Batch equivalent
.\libscript.cmd ls-remote fmt
.\libscript.cmd install fmt latest
.\libscript.cmd use fmt latest
.\libscript.cmd which fmt
```

## Installation & Isolation

- **Default Isolation**: Installs versioned artifacts under `${LIBSCRIPT_HOME}/fmt/<version>`
  (default `~/.libscript/fmt/<version>`) and synchronizes `O(1)` shims in `${LIBSCRIPT_HOME}/bin`
  without polluting system paths.
- **Override Strategy**: Control installation via `FMT_INSTALL_METHOD` (or global
  `LIBSCRIPT_DEFAULT_INSTALL_METHOD`): `libscript_native`, `from-source` (via
  `engine/common/source_builder.*`), or `system` (via `engine/common/pkg_mgr.*`).

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running setup.

<!-- BEGIN_VARS -->

| Variable             | Description                                                                                                                                  | Default       | Aliases/Examples |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ---------------- |
| `FMT_INSTALL_METHOD` | How to install fmt. 'libscript_native' uses isolated version dirs, 'system' uses OS package manager, and 'from-source' compiles from source. | `from-source` |                  |
| `FMT_VERSION`        | Specific version of fmt to install.                                                                                                          | `11.0.2`      | latest, lts      |
| `FMT_DOWNLOAD_URL`   | Override URL for downloading fmt binary or archive artifacts.                                                                                | `none`        |                  |
| `FMT_RELEASES_URL`   | Override URL for querying fmt available remote releases.                                                                                     | `none`        |                  |
| `FMT_RUN_TESTS`      | Whether to build and execute the upstream {fmt} CTest suite during source builds.                                                            | `none`        |                  |
| `FMT_SOURCE_DIR`     | Extracted {fmt} source directory containing include/fmt/format-inl.h and src/format.cc for single-TU benchmarks.                             | `none`        |                  |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
