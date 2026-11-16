# Common

## Purpose & Current State

**Purpose**: This document provides context and technical details for the `_common` component (part
of `_lib`) within the LibScript ecosystem. This component provides shared utilities, core functions,
and baseline scripts that are universally utilized by other modules across the LibScript framework
to ensure consistent execution across different platforms.

## Usage

This directory contains the essential shared scripts for `_common`. It is designed to work both as a
local version manager (similar to `rvm`, `nvm`, `pyenv`, or `uv`) for managing common toolkit
versions, and can be seamlessly invoked from the global version manager `libscript`.

Furthermore, these common utilities are foundational and can be used by LibScript to build and
provision bigger stacks, such as WordPress, Open edX, Nextcloud, and other enterprise-grade
application deployments.

You can install, start, stop, package, and uninstall \_common using the global `libscript` command
or the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install _common

./cli.sh install _common

./libscript.sh start _common
./cli.sh start _common

./libscript.sh stop _common
./cli.sh stop _common

./libscript.sh package-as docker _common
./cli.sh package-as docker _common

./libscript.sh uninstall _common
./cli.sh uninstall _common
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install _common

:: Local CLI
cli.cmd install _common

:: Start and Stop
libscript.cmd start _common
cli.cmd start _common

libscript.cmd stop _common
cli.cmd stop _common

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi _common
cli.cmd package-as msi _common

:: Uninstall
libscript.cmd uninstall _common
cli.cmd uninstall _common
```

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh`: Fallback installation logic using the package manager mapper.
- `pkg_mgr.sh` / `pkg_mgr.cmd`: Multi-ecosystem package manager abstraction supporting explicit
  `--pkg-mgr=<pm>` overrides (`apt-get`, `apk`, `dnf`, `brew`, `winget`, `choco`, `scoop`, `nix`,
  `spack`, `vcpkg`, etc.) and automatic package manager bootstrapping.
- `source_builder.sh` / `source_builder.cmd`: Generic source compilation engine supporting Mode 2
  (`--from-source --toolchain=default`) and Mode 3
  (`--from-source --toolchain=gcc|clang|tcc|custom-cc`) with `build-metrics.json` telemetry.
- `test.sh` / `test.cmd`: Verification scripts to ensure the component is installed and functioning
  correctly.
- `base_vars.schema.json`: Canonical JSON Schema for core framework-wide variables.

## Core Global Variables (`base_vars.schema.json`)

<!-- BEGIN_VARS -->

| Variable                           | Description                                                                                                                                                                                                                                                       | Default            | Aliases/Examples                |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------- |
| `LIBSCRIPT_HOME`                   | Base installation prefix where LibScript installs isolated component versions.                                                                                                                                                                                    | `none`             | PREFIX                          |
| `LIBSCRIPT_DATA_DIR`               | Base data directory for runtime component state, databases, and service configurations.                                                                                                                                                                           | `none`             |                                 |
| `LIBSCRIPT_CACHE_DIR`              | Directory where cached release metadata and build artifacts are stored.                                                                                                                                                                                           | `none`             |                                 |
| `LIBSCRIPT_BUILD_DIR`              | Scratch build directory used when compiling components from source.                                                                                                                                                                                               | `none`             |                                 |
| `LIBSCRIPT_DOWNLOAD_DIR`           | Staging directory where downloaded component archives and binaries are cached.                                                                                                                                                                                    | `none`             | DOWNLOAD_DIR                    |
| `LIBSCRIPT_LOG_DIR`                | Base directory where component and lifecycle log files are written.                                                                                                                                                                                               | `none`             | LOGS_DIR, LIBSCRIPT_LOGS_DIR    |
| `LIBSCRIPT_LOG_FILE`               | Explicit file path to append structured or text logs to in addition to standard output.                                                                                                                                                                           | `none`             |                                 |
| `LIBSCRIPT_LOG_LEVEL`              | Minimum logging severity level (0=DEBUG, 1=INFO, 2=SUCCESS, 3=WARN, 4=ERROR).                                                                                                                                                                                     | `1`                |                                 |
| `LIBSCRIPT_LOG_FORMAT`             | Output serialization format for lifecycle log messages (text or json).                                                                                                                                                                                            | `text`             |                                 |
| `LIBSCRIPT_OUTPUT_FORMAT`          | Shell or data output format emitted by env and status commands (sh, cmd, ps1, dotenv, json, text).                                                                                                                                                                | `none`             | FORMAT                          |
| `LIBSCRIPT_DEBUG`                  | Flag (0 or 1) enabling verbose debug and STACK recursion trace output across LibScript.                                                                                                                                                                           | `0`                |                                 |
| `LIBSCRIPT_OFFLINE`                | Flag (0 or 1) indicating offline execution mode using pre-hydrated local caches.                                                                                                                                                                                  | `0`                |                                 |
| `LIBSCRIPT_FORCE_OFFLINE`          | Strict air-gapped flag (0 or 1) that immediately aborts execution if any network call is attempted.                                                                                                                                                               | `0`                |                                 |
| `LIBSCRIPT_FORCE_FETCH`            | Flag (0 or 1) forcing remote artifact re-fetching even when present in the local download cache.                                                                                                                                                                  | `0`                |                                 |
| `LIBSCRIPT_DRY_RUN`                | Flag (0 or 1) to simulate lifecycle and service operations without executing mutating commands.                                                                                                                                                                   | `0`                |                                 |
| `LIBSCRIPT_AUTO_USE`               | Flag (0 or 1) automatically activating an installed component version in LIBSCRIPT_HOME/bin upon installation.                                                                                                                                                    | `0`                |                                 |
| `LIBSCRIPT_DRY_RUN_PKG_MGR`        | Flag (0 or 1) to simulate OS package manager invocations without mutating the host system.                                                                                                                                                                        | `0`                |                                 |
| `LIBSCRIPT_DEFAULT_INSTALL_METHOD` | Global override for how software should be installed ('libscript_native' prebuilt binary, 'from-source' compiled from source code, or 'system' via OS/selected package manager).                                                                                  | `libscript_native` | LIBSCRIPT_GLOBAL_INSTALL_METHOD |
| `LIBSCRIPT_PKG_MGR`                | Explicit package manager override for 'system' or package-manager-driven installations (e.g., 'apt-get', 'apk', 'dnf', 'yum', 'zypper', 'pacman', 'brew', 'port', 'pkg', 'xbps', 'emerge', 'winget', 'choco', 'scoop', 'nix', 'guix', 'spack', 'vcpkg', 'conan'). | `none`             |                                 |
| `LIBSCRIPT_WINDOWS_PKG_MGR`        | Global package manager override on Windows and MS-DOS hosts (libscript, winget, choco, scoop, vcpkg, rapps).                                                                                                                                                      | `winget`           |                                 |
| `LIBSCRIPT_SKIP_SYSTEM_DEPS`       | Flag (0 or 1) to skip OS-level system dependency installation during component setup.                                                                                                                                                                             | `0`                |                                 |
| `LIBSCRIPT_PROFILE`                | Active configuration profile identifier (e.g., dev, prod, minimal, hpc).                                                                                                                                                                                          | `none`             |                                 |
| `LIBSCRIPT_VERSION`                | Requested target package version override when not specified via <COMP>_VERSION.                                                                                                                                                                                  | `none`             |                                 |
| `LIBSCRIPT_SERVICE_NAME`           | Explicit service unit identifier overriding the default libscript_<component> service name.                                                                                                                                                                       | `none`             |                                 |
| `LIBSCRIPT_SERVICE_RUN_AS_USER`    | System user account under which daemonized component services execute.                                                                                                                                                                                            | `none`             |                                 |
| `LIBSCRIPT_LISTEN_ADDRESS`         | Global fallback bind address for network-listening components.                                                                                                                                                                                                    | `none`             |                                 |
| `LIBSCRIPT_LISTEN_PORT`            | Global fallback TCP port for network-listening components.                                                                                                                                                                                                        | `none`             |                                 |
| `LIBSCRIPT_LISTEN_SOCKET`          | Global fallback UNIX domain socket path for listening components.                                                                                                                                                                                                 | `none`             |                                 |
| `LIBSCRIPT_TARGET_SYSROOT`         | Optional target root filesystem path when staging components into chroots or OS images.                                                                                                                                                                           | `none`             | LIBSCRIPT_TARGET_ROOTFS         |
| `LIBSCRIPT_ARIA2_EXPORT_FILE`      | File path to export aria2-compatible download manifests instead of downloading immediately.                                                                                                                                                                       | `none`             |                                 |
| `FORCE_REINSTALL`                  | Flag (0 or 1) forcing re-downloading and reinstalling a component even when already present.                                                                                                                                                                      | `0`                |                                 |
| `FORCE_REBUILD`                    | Flag (0 or 1) forcing recompilation or service unit regeneration from scratch.                                                                                                                                                                                    | `0`                |                                 |

<!-- END_VARS -->

## Internal Runtime & Memoization Variables

The following `LIBSCRIPT_*` variables are internal mutable/computed contracts passed between core
modules (excluded from user-facing `vars.schema.json` files and validated via
`is_internal_runtime_var` in `devtools/audit/audit_schema_vars.{sh,cmd,ps1}`):

- `LIBSCRIPT_ROOT_DIR`: Resolved repository root directory.
- `LIBSCRIPT_OVERRIDE_CHANGED`: Internal return flag set by `libscript_override_service_env`.
- `LIBSCRIPT_RESOLVED_CC_BIN`, `LIBSCRIPT_RESOLVED_CC_ID`, `LIBSCRIPT_RESOLVED_CC_VERSION`,
  `LIBSCRIPT_RESOLVED_CXX_BIN`, `LIBSCRIPT_LAST_PEAK_RSS_KB`, `LIBSCRIPT_LAST_COMPILE_TIME_MS`,
  `LIBSCRIPT_EXTRACTED_SRC_DIR`, `LIBSCRIPT_BUILD_TARGET_DIR`, `LIBSCRIPT_BASE_DIR`: Internal
  compiler/source-build outputs computed by `source_builder.{sh,cmd}`.
- `LIBSCRIPT_HW_CPU_MODEL`, `LIBSCRIPT_HW_PHYS_CORES`, `LIBSCRIPT_HW_PERF_CORES`,
  `LIBSCRIPT_HW_NUMA_NODES`: Hardware topology values probed by `hw_tune.{sh,cmd}`.
- `LIBSCRIPT_BENCH_CLOCK_NS_BIN`, `LIBSCRIPT_BENCH_PROBE_BIN`,
  `LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA`: Internal compiled timing probe paths and unit-test fault
  injection toggles.
- `LIBSCRIPT_INTERNAL_START`, `LIBSCRIPT_COMPONENT_CORE_LIB_ONLY`, `LIBSCRIPT_MOCK_SYSTEMD`,
  `LIBSCRIPT_DUMMY_NO_RUN`, `LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB`,
  `LIBSCRIPT_DISABLE_CHECKSUM_TXT_UPDATE`: Internal router, cache-hydration, and test-harness flags.

## Platform Support

- Linux
- macOS
- Windows

## Version Management

As outlined in the core philosophy, `libscript` manages the versions natively. Installations are
isolated by default in `~/.libscript/<component>/<version>` and do not pollute global system paths.
