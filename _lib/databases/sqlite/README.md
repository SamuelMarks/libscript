# SQLite

## Purpose & Current State

This document provides context and technical details for the **SQLite** component (part of the
`_storage` module) within the LibScript ecolibscript_native. SQLite is a C-language library that
implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine.

This component works both as a local version manager for SQLite (similar to `rvm`, `nvm`, `pyenv`,
or `uv`) and can be natively invoked from the global version manager `libscript`. Because of this
flexibility, SQLite can be used by LibScript to provision and build bigger, more complex software
stacks (like WordPress, Open edX, Nextcloud, etc.).

## Usage

You can install, start, stop, package, and uninstall sqlite using the global `libscript` command or
the local CLI.

**Unix (Linux/macOS):**

```sh

./libscript.sh install sqlite

./cli.sh install sqlite

./libscript.sh start sqlite
./cli.sh start sqlite

./libscript.sh stop sqlite
./cli.sh stop sqlite

./libscript.sh package-as docker sqlite
./cli.sh package-as docker sqlite

./libscript.sh uninstall sqlite
./cli.sh uninstall sqlite
```

**Windows:**

```cmd
:: Global Orchestrator
libscript.cmd install sqlite

:: Local CLI
cli.cmd install sqlite

:: Start and Stop
libscript.cmd start sqlite
cli.cmd start sqlite

libscript.cmd stop sqlite
cli.cmd stop sqlite

:: Package (e.g., as MSI installer)
libscript.cmd package-as msi sqlite
cli.cmd package-as msi sqlite

:: Uninstall
libscript.cmd uninstall sqlite
cli.cmd uninstall sqlite
```

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->

| Variable                        | Description                                                                                                                                                                                                                                                         | Default                                                                         | Aliases/Examples        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ----------------------- |
| `LIBSCRIPT_TARGET_SYSROOT`      | Target root filesystem staging path when provisioning chroots or OS images.                                                                                                                                                                                         | `none`                                                                          | LIBSCRIPT_TARGET_ROOTFS |
| `LIBSCRIPT_TARGET_ARCH`         | Target CPU architecture when cross-compiling or building OS images.                                                                                                                                                                                                 | `none`                                                                          |                         |
| `LIBSCRIPT_TARGET_LIBC`         | Target C standard library implementation (glibc, musl, uclibc, picolibc, nolibc, msvcrt).                                                                                                                                                                           | `none`                                                                          |                         |
| `LIBSCRIPT_TARGET_OS`           | Target operating system identifier when provisioning or cross-compiling.                                                                                                                                                                                            | `none`                                                                          |                         |
| `LIBSCRIPT_HOST_ROOT`           | Isolated cross-toolchain host directory prefix when bootstrapping or executing inside a container/chroot.                                                                                                                                                           | `none`                                                                          |                         |
| `LIBSCRIPT_STAGE`               | Active multi-stage T3 execution plan stage identifier (e.g., stage0, stage1, stage2, stage3).                                                                                                                                                                       | `none`                                                                          |                         |
| `LIBSCRIPT_IMAGE_BUILD`         | Flag (0 or 1) indicating offline sysroot/image synthesis mode so service installers stage unit files without starting host daemons.                                                                                                                                 | `0`                                                                             |                         |
| `LIBSCRIPT_STRICT_IMAGE_BUILD`  | Flag (0 or 1) enforcing strict native image synthesis and rejecting missing-tool stub fallbacks without writing completion stamps.                                                                                                                                  | `0`                                                                             |                         |
| `LIBSCRIPT_ALLOW_STUB`          | Flag (0 or 1) explicitly permitting structural stub artifacts during unit and dry-run testing when hypervisor or mkfs tools are absent.                                                                                                                             | `0`                                                                             |                         |
| `LIBSCRIPT_VM_WORKER`           | Virtualization worker backend override (docker, wsl2, qemu, bhyve, omnios-vm) for cross-OS disk and filesystem synthesis.                                                                                                                                           | `none`                                                                          |                         |
| `LIBSCRIPT_UNIKERNEL_FRAMEWORK` | Target unikernel build framework (unikraft, nanos, osv, rumprun, mirageos) when synthesizing unikernel appliances.                                                                                                                                                  | `none`                                                                          |                         |
| `LIBSCRIPT_RELEASEVER`          | Target Enterprise Linux major release version passed to dnf --releasever when staging into LIBSCRIPT_TARGET_SYSROOT.                                                                                                                                                | `9`                                                                             |                         |
| `LIBSCRIPT_SYSTEMD_DIR`         | Override directory for systemd unit and drop-in override files (defaults to /etc/systemd/system).                                                                                                                                                                   | `none`                                                                          |                         |
| `LIBSCRIPT_LIB_SYSTEMD_DIR`     | Override directory for vendor systemd unit files (defaults to /lib/systemd/system).                                                                                                                                                                                 | `none`                                                                          |                         |
| `LIBSCRIPT_ETC_DIR`             | Override root configuration directory for system service config files (defaults to /etc).                                                                                                                                                                           | `none`                                                                          |                         |
| `LIBSCRIPT_INITD_DIR`           | Override directory for SysV/OpenRC init.d scripts (defaults to /etc/init.d).                                                                                                                                                                                        | `none`                                                                          |                         |
| `LIBSCRIPT_FREEBSD_RCD_DIR`     | Override directory for FreeBSD rc.d service scripts (defaults to /usr/local/etc/rc.d).                                                                                                                                                                              | `none`                                                                          |                         |
| `LIBSCRIPT_RUN_DIR`             | Override runtime PID/socket directory (defaults to /var/run).                                                                                                                                                                                                       | `none`                                                                          |                         |
| `LIBSCRIPT_USR_LOCAL_BIN`       | Override directory for locally installed system binaries (defaults to /usr/local/bin).                                                                                                                                                                              | `none`                                                                          |                         |
| `LIBSCRIPT_USR_LOCAL_ETC`       | Override directory for locally installed system configuration files (defaults to /usr/local/etc).                                                                                                                                                                   | `none`                                                                          |                         |
| `LIBSCRIPT_HOME_BASE`           | Base parent directory for user home directories (defaults to /home).                                                                                                                                                                                                | `none`                                                                          |                         |
| `LIBSCRIPT_ROOT_HOME`           | Root user home directory override (defaults to /root).                                                                                                                                                                                                              | `none`                                                                          |                         |
| `LIBSCRIPT_BUILD_TOOLCHAIN`     | Toolchain selector used when building components from source ('default' uses the platform default C/C++ compiler via _lib/languages/c, whereas 'gcc', 'clang', 'tcc', 'custom-cc', or an explicit binary path compiles the component with that specific toolchain). | `default`                                                                       |                         |
| `LIBSCRIPT_CUSTOM_CC_BIN`       | Optional filesystem path to a custom C compiler binary when LIBSCRIPT_BUILD_TOOLCHAIN='custom-cc'.                                                                                                                                                                  | `none`                                                                          |                         |
| `LIBSCRIPT_BUILD_CFLAGS`        | Extra CFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                 | `none`                                                                          |                         |
| `LIBSCRIPT_BUILD_LDFLAGS`       | Extra LDFLAGS passed to source builds for components compiling native C/C++ sources.                                                                                                                                                                                | `none`                                                                          |                         |
| `LIBSCRIPT_SOURCE_WORKDIR`      | Working directory used for extracting and compiling source tarballs.                                                                                                                                                                                                | `none`                                                                          |                         |
| `LIBSCRIPT_HW_CORES`            | Detected or overridden CPU core count for auto-tuning services and parallel builds.                                                                                                                                                                                 | `none`                                                                          |                         |
| `LIBSCRIPT_HW_MEM_MB`           | Detected or overridden system memory in MiB for auto-tuning service buffer pools.                                                                                                                                                                                   | `none`                                                                          |                         |
| `LIBSCRIPT_HW_NVME`             | Detected or overridden NVMe storage presence flag for I/O scheduler and database tuning.                                                                                                                                                                            | `none`                                                                          |                         |
| `LIBSCRIPT_HW_SIMD`             | Detected or overridden CPU SIMD instruction set capabilities (e.g., avx2, avx512, neon).                                                                                                                                                                            | `none`                                                                          |                         |
| `SQLITE_VERSION`                | Specific version of SQLite to install or compile (e.g., '3.46.1' or 'latest').                                                                                                                                                                                      | `latest`                                                                        | latest, stable          |
| `SQLITE_INSTALL_METHOD`         | How to install SQLite ('libscript_native' prebuilt binary, 'from-source' compiled from the C amalgamation, 'system' via OS/selected package manager, or third-party version managers).                                                                              | `libscript_native`                                                              |                         |
| `SQLITE_PKG_MGR`                | Specific package manager to use when installing SQLite via package manager (e.g., apt-get, apk, dnf, brew, winget, choco, scoop, nix, vcpkg).                                                                                                                       | `none`                                                                          |                         |
| `SQLITE_BUILD_TOOLCHAIN`        | Build toolchain used when SQLITE_INSTALL_METHOD='from-source' ('default' uses platform default C compiler; 'gcc', 'clang', 'tcc', 'custom-cc', or a binary path uses that custom compiler).                                                                         | `default`                                                                       |                         |
| `SQLITE_COMPILER`               | Alias for SQLITE_BUILD_TOOLCHAIN specifying the C compiler for source builds.                                                                                                                                                                                       | `default`                                                                       |                         |
| `SQLITE_CFLAGS`                 | Compiler flags passed when compiling the SQLite amalgamation from source.                                                                                                                                                                                           | `-O2 -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE` |                         |
| `SQLITE_LDFLAGS`                | Linker flags passed when linking the SQLite CLI and library from source.                                                                                                                                                                                            | `-lpthread -ldl -lm`                                                            |                         |
| `SQLITE_SINGLE_THREADED`        | When true, compiles SQLite with -DSQLITE_THREADSAFE=0 and -DSQLITE_OMIT_LOAD_EXTENSION=1 for minimal C compilers.                                                                                                                                                   | `none`                                                                          |                         |
| `SQLITE_AMALGAMATION_URL`       | Optional explicit download URL for the SQLite C amalgamation archive.                                                                                                                                                                                               | `none`                                                                          |                         |
| `SQLITE_AMALGAMATION_YEAR`      | Release year directory on sqlite.org used when constructing the default amalgamation URL.                                                                                                                                                                           | `2024`                                                                          |                         |
| `SQLITE_BUILD_SHARED_LIB`       | Whether to also compile the shared library (libsqlite3.so / libsqlite3.dylib / sqlite3.dll) during from-source builds.                                                                                                                                              | `true`                                                                          |                         |
| `LIBSCRIPT_LISTEN_PORT`         | Global port to listen on                                                                                                                                                                                                                                            | `none`                                                                          |                         |
| `LIBSCRIPT_LISTEN_ADDRESS`      | Global address to listen on                                                                                                                                                                                                                                         | `none`                                                                          |                         |
| `LIBSCRIPT_LISTEN_SOCKET`       | Global unix socket to listen on                                                                                                                                                                                                                                     | `none`                                                                          |                         |
| `SQLITE_LISTEN_PORT`            | Port for SQLITE to listen on                                                                                                                                                                                                                                        | `none`                                                                          |                         |
| `SQLITE_LISTEN_ADDRESS`         | Address for SQLITE to listen on                                                                                                                                                                                                                                     | `none`                                                                          |                         |
| `SQLITE_LISTEN_SOCKET`          | Unix socket for SQLITE to listen on                                                                                                                                                                                                                                 | `none`                                                                          |                         |
| `SQLITE_BIN`                    | Configuration variable SQLITE_BIN for sqlite.                                                                                                                                                                                                                       | `none`                                                                          |                         |
| `SQLITE_COMPARE_COMPILERS`      | Configuration variable SQLITE_COMPARE_COMPILERS for sqlite.                                                                                                                                                                                                         | `none`                                                                          |                         |
| `SQLITE_DOWNLOAD_URL`           | Override URL for downloading sqlite binary or archive artifacts.                                                                                                                                                                                                    | `none`                                                                          |                         |
| `SQLITE_EFFECTIVE_CFLAGS`       | Configuration variable SQLITE_EFFECTIVE_CFLAGS for sqlite.                                                                                                                                                                                                          | `none`                                                                          |                         |
| `SQLITE_EFFECTIVE_LDFLAGS`      | Configuration variable SQLITE_EFFECTIVE_LDFLAGS for sqlite.                                                                                                                                                                                                         | `none`                                                                          |                         |
| `SQLITE_PATH`                   | Filesystem directory or path configuration for sqlite (SQLITE_PATH).                                                                                                                                                                                                | `none`                                                                          |                         |
| `SQLITE_PREFIX`                 | Configuration variable SQLITE_PREFIX for sqlite.                                                                                                                                                                                                                    | `none`                                                                          |                         |
| `SQLITE_RELEASES_URL`           | Override URL for querying sqlite available remote releases.                                                                                                                                                                                                         | `none`                                                                          |                         |
| `SQLITE_SRC_URL`                | Upstream sqlite-src archive URL providing test/speedtest1.c alongside the amalgamation.                                                                                                                                                                             | `none`                                                                          |                         |
| `SQLITE_STAGE_DIR`              | Destination directory where stage-benchmark-inputs extracts sqlite3.c, shell.c, sqlite3.h, and speedtest1.c.                                                                                                                                                        | `none`                                                                          |                         |

Global framework variables (such as `LIBSCRIPT_HOME`, `LIBSCRIPT_CACHE_DIR`, `LIBSCRIPT_OFFLINE`,
and `LIBSCRIPT_DEFAULT_INSTALL_METHOD`) are documented in `engine/common/README.md`.
<!-- END_VARS -->

## Architecture

- `setup.sh`: The main entrypoint that resolves the OS and invokes the correct script.
- `setup_generic.sh` / `setup_generic.cmd`: Multi-mode provisioner supporting Mode 1
  (`--pkg-mgr=<pm>`), Mode 2 (`--from-source --toolchain=default`), and Mode 3
  (`--from-source --toolchain=gcc|clang|tcc|custom-cc`).
- `test.sh` / `test.cmd`: 6-stage relational SQL torture suite with deterministic SHA-256 output
  digest verification.
- `compare_compilers.sh` / `compare_compilers.cmd`: 4-way differential C compiler benchmark and
  verification harness (`build/sqlite-compiler-comparison.json`).
- `vars.schema.json`: The schema definition for the CLI arguments.

## Variables

See `vars.schema.json` for details on available variables.

## Platform Support

<!-- BEGIN_PLATFORMS -->

- Linux
- macOS
- Windows

<!-- END_PLATFORMS -->
