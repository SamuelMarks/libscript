# Dependency Management

LibScript uses a custom, lightweight dependency mapper to abstract over the differences between operating system package managers.

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
