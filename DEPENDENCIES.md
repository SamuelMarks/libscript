# Dependency Management

## Purpose & Current State

**Purpose**: This document explains the cross-platform dependency management layer (`pkg_mapper.sh` and `pkg_mgr.sh`), which automatically resolves and installs native OS packages. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: LibScript functions as a comprehensive global and per-component package manager, featuring a robust core CLI (`libscript.sh`, `libscript.cmd`, `libscript.bat`). It includes multi-platform toolchain support (Rust, Python, Node, Go, Java, C/C++), servers (Postgres, Nginx, Valkey), and advanced environment querying (`env` subcommand). It natively supports generating deployment configurations (`package_as docker`, `package_as docker_compose`, `package_as msi`, `package_as innosetup`, `package_as nsis`, `package_as TUI`) with deep installer customization, automated parallel dependency downloading and resolution via `libscript.json`, and robust uninstall lifecycle hooks (`uninstall.sh`/`uninstall.cmd`) for cleanly removing binaries, configs, and services. It natively handles deep semantic versioning, global `--secrets` extraction, caching, OpenBao/Vault generation, local caching via SQLite (`db-search`, `update-db`), explicit error handling for unsupported actions, and background process serving. Ongoing development targets extended registry integrations and dynamic web server routing.

## How it Works

When a component script calls `depends curl jq libssl-dev`, the following lifecycle occurs:

1. **OS Detection:** `_lib/_common/os_info.sh` determines the OS (Linux, macOS, FreeBSD, etc.) and distribution (Debian, Alpine, RHEL, etc.).
2. **Package Manager Detection:** `_lib/_common/pkg_mgr.sh` iterates through known package managers (`apt-get`, `apk`, `dnf`, `brew`, `pacman`, etc.) and sets `$PKG_MGR` to the first available one.
3. **Package Mapping:** `_lib/_common/pkg_mapper.sh` intercepts the requested package names. Since different distributions name packages differently (e.g., `libssl-dev` on Debian vs `openssl-dev` on Alpine), `pkg_mapper.sh` translates the generic name to the OS-specific name.
4. **Verification:** The script checks if the mapped package is already installed (e.g., via `dpkg-query`, `apk info`, `rpm -q`).
5. **Installation:** If not installed, the package manager is invoked non-interactively to install the dependency.

## Package Mapper

The `pkg_mapper.sh` file contains a mapping function `map_package`. If you add a new dependency to a script and find it fails on Alpine or RHEL because the package name is different, you must update `pkg_mapper.sh` to include a translation case.

Example:
```sh
map_package() {
  pkg="${1}"
  case "${pkg}" in
    'libssl-dev')
      case "${TARGET_OS}" in
        'alpine') printf 'openssl-dev' ;;
        'rhel'|'fedora'|'centos') printf 'openssl-devel' ;;
        *) printf 'libssl-dev' ;;
      esac
      ;;
    *)
      printf '%s' "${pkg}"
      ;;
  esac
}
```

## Global vs Local Install Methods

As mentioned in the component READMEs, you can define `LIBSCRIPT_GLOBAL_INSTALL_METHOD` (e.g., `system`, `source`) to dictate how higher-level tools (like Python or Node.js) are installed. The package manager abstraction strictly handles OS-level dependencies (C libraries, basic utilities like `curl` or `tar`).
