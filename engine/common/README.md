# Tier 0 (`T0`) Core Standard Library (`engine/common/`)

## Overview

`engine/common/` is the zero-dependency `T0` standard library for the entire LibScript substrate. It
is **not** an installable end-user package; instead, every atomic recipe in `_lib/` (`T1`/`T2`),
artifact synthesizer in `synthesis/` (`T3`), cloud provider in `infrastructure/` (`T4`), workload
driver in `workloads/` (`T5`), and cross-cutting trait in `traits/` (`Plane A`) sources these
primitives in pure POSIX `/bin/sh` and native Windows Batch (`.cmd`) / PowerShell (`.ps1`).

## Core Modules

- **Package & Artifact Transport (`pkg_mgr.{sh,cmd}`, `pkg_mapper.{sh,cmd}`, `pkg_map.tsv`,
  `fetch_checksum.{sh,cmd}`, `verify_signature.{sh,cmd}`)**:
  - Centralized network download and checksum/signature verification layer (`libscript_download`,
    `libscript_fetch_stdout`), enforcing air-gapped `LIBSCRIPT_OFFLINE=1` local cache resolution and
    mapping logical package names across 20+ OS and ecosystem package managers (`apt-get`, `apk`,
    `dnf`, `pacman`, `pkg`, `pkgin`, `brew`, `winget`, `choco`, `scoop`, `nix`, `spack`, `vcpkg`,
    `rapps`, and native Win32/MS-DOS `libscript` component PMs).
- **Version Manager & Component Lifecycle (`component_core.{sh,cmd,ps1}`, `versioning.{sh,cmd}`,
  `semver.{jq,sh,cmd}`, `cli.{sh,cmd,ps1}`, `setup_base.{sh,cmd}`, `uninstall_base.{sh,cmd}`,
  `test_base.{sh,cmd}`)**:
  - Implements isolated `${LIBSCRIPT_HOME}/<component>/<version>` sandboxes, `O(1)` symlink/shim
    synchronization in `${LIBSCRIPT_HOME}/bin` (`libscript_sync_active_bin` /
    `libscript_cleanup_active_bin`), semantic version sorting, and standard component CLI verbs
    (`install`, `uninstall`, `ls`, `ls-remote`, `use`, `which`, `env`, `test`).
- **Source Compilation & Binary Patching (`source_builder.{sh,cmd}`, `elf_verneed_patch.{sh,cmd}`,
  `hw_tune.{sh,cmd}`)**:
  - Multi-toolchain source build engine
    (`--from-source --toolchain=default|gcc|clang|tcc|edgcpp|custom-cc`) emitting
    `build-metrics.json` telemetry, ELF `DT_VERNEED` compatibility patching, and CPU/RAM parallelism
    auto-tuning.
- **Daemon Supervision & Lifecycle Hooks (`service.{sh,cmd}`, `service_install.{sh,cmd}`,
  `daemonize.{sh,cmd,ps1}`, `daemon_launcher.{sh,cmd,ps1}`, `hooks.{sh,cmd}`,
  `component_hook_impl.{sh,cmd}`, `upgrade_engine.{sh,cmd}`)**:
  - Unified service registration across `systemd`, `openrc`, `runit`, `s6`, `dinit`, `sysvinit`,
    `launchd`, `smf`, and Windows Service Control Manager, plus physical/logical lifecycle hook
    dispatch (`configure`, `probe`, `backup`, `restore`, `upgrade`, `rollback`, `provision_tenant`).
- **Environment, Template & Filesystem Utilities (`context.{sh,cmd,ps1}`, `os_info.{sh,cmd}`,
  `paths.{sh,cmd}`, `envsubst_safe.{sh,cmd}`, `find_replace.{sh,cmd}`, `settings_updater.{sh,cmd}`,
  `cow_snapshot.{sh,cmd}`, `disk_discovery.{sh,cmd}`, `format_fs.{sh,cmd}`, `vm_builder.{sh,cmd}`,
  `remote_sync.{sh,cmd}`, `tfrc_guard.{sh,cmd}`)**:
  - Target OS/architecture/libc detection, safe template substitution without `eval`, Copy-on-Write
    snapshot helpers (`ZFS`/`Btrfs`), filesystem formatting, VM builder delegation for Option A
    Win32 boundaries, SSH/WinRM synchronization, and `$0.00` TFRC TPU quota guardrails.
- **Zero-Emulation Native Helpers (`win32/`, `dos32/`, `dos_83.{sh,cmd}`, `dos_83_map.tsv`,
  `_noop/`)**:
  - Native C Win32 PE helpers (`ls_daemon.c`, `ls_elevate.c`, `ls_pe_arch.c`), 32-bit MS-DOS
    (`DOS32A` + OpenWatcom) helpers (`ls_dash_dos.c`, `ls_watt_curl.c`, `ls_wincmd.c`), 8.3 short
    filename mapping, and the `_noop` null-provider fallback module.

## Global Framework Variables

The following global environment variables (`engine/schemas/base_vars.schema.json`) apply across all
LibScript tiers and components:

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
