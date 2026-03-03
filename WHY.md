# Why LibScript?

## Purpose & Current State

**Purpose**: This document explains the rationale and philosophy behind LibScript's creation, emphasizing its zero-dependency bootstrap capability, inspectability, OS-native integration, and idempotency. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## 1. Zero Dependencies (The Bootstrap Problem)
If you want to run Ansible, you need Python installed on the target machine. If you want to run Chef, you need Ruby. LibScript solves the "bootstrap problem." It requires strictly POSIX-compliant `/bin/sh` (or `cmd.exe` on Windows). You can curl a LibScript bundle and run it on a completely bare, freshly installed operating system without installing anything else first.

## 2. Inspectability and Debuggability
When a configuration management tool fails, you often have to dig through complex DSLs (Domain Specific Languages) and abstract error traces. When a LibScript component fails, it's just a shell script. You can run it with `sh -x setup.sh` and see exactly which command failed, right down to the native package manager call.

## 3. Native OS Integration vs Containers
Docker is excellent for packaging applications, but terrible for configuring a developer's local workstation or setting up an OS-native environment where performance, direct hardware access, or deep OS integration (like GUI apps, VPNs, or system daemons) is required. LibScript targets the host OS natively.

## 4. Composability
LibScript acts as a standard library for shell scripts. Instead of copying and pasting the same 50 lines of "how to detect the OS and install curl" across every project you own, you simply depend on `_lib/_common/os_info.sh` and `pkg_mgr.sh`.

## 5. Idempotency without the Overhead
While shell scripts are typically imperative and not idempotent, LibScript enforces idempotent design patterns in its components. This brings the primary benefit of declarative systems (you can run it 10 times and the result is the same) without the massive footprint.
