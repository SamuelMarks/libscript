# Libscript: What a Version Manager Should Look Like

This document defines the architectural standard for how `libscript` components must behave to act
as true, native version managers.

By adhering to this specification, `libscript` ensures that developers can install, isolate, and
switch between multiple versions of a language or toolchain without relying on third-party
orchestrators (like `pyenv`, `nvm`, `rustup`, or `sdkman`) and without polluting global system
paths.

## 1. Core Philosophy

1. **Zero External Dependencies by Default**: A component must natively download binaries or compile
   from source. It must not delegate to third-party version managers unless explicitly overridden by
   the user.
2. **Version Isolation**: Every installed version must exist in its own isolated directory.
3. **Non-Destructive**: Installing a new version must never overwrite or delete an existing version.
4. **Dynamic Resolution**: The active version is determined purely by environment variables
   manipulating the `PATH` (and other relevant vars like `JAVA_HOME`), making it safe for concurrent
   use in different terminal sessions.

## 2. Directory Structure

All native `libscript` installations must be scoped to a standardized base directory to prevent
polluting global user directories.

This base directory MUST be configurable via the `LIBSCRIPT_HOME` environment variable, defaulting
to `~/.libscript` if unset. This allows developers to easily isolate installations for debugging
(e.g., `LIBSCRIPT_HOME=/tmp/.libscript`) or system-wide provisioning (e.g.,
`LIBSCRIPT_HOME=/opt/.libscript`).

**Standard Path Pattern:** `${LIBSCRIPT_HOME}/<component>/<exact_version>`

_Example for Python (assuming default `LIBSCRIPT_HOME`):_

- `~/.libscript/python/3.11.9/bin/python`
- `~/.libscript/python/3.12.0/bin/python`

**Aliases via Symlinks & `O(1)` Active Bin Farm:** When a user requests an alias (like `lts`,
`latest`, `stable`, or `beta`), the setup script resolves the exact version, installs it to its
exact version directory, and creates a symlink/junction for the alias. When `default` is updated via
`libscript use <pkg> <ver>` (or `install --use`), `_lib/_common/versioning.{sh,cmd}` atomically
synchronizes executable shims in `${LIBSCRIPT_HOME}/bin` (`O(1)` `PATH` entry) and redirects or
prunes stale shims on `uninstall`.

**Multi-Tool Workspace Pins (`.libscript-version`):** Workspaces may pin multiple toolchains in a
single `.libscript-version` file (`rust=1.85.0`, `nodejs=22.14.0`, `python=3.12.8`). Running
`./libscript.sh resolve-env --write=<file>` walks upward from `$PWD` and emits a deterministic
sourced activation file without `eval`.

**Capability-Typed Manifests & Toolchain Sub-Artifacts:** Every `manifest.json` declares its
`"capabilities"` (`"versioned-artifact"`, `"service-daemon"`, `"sysroot-library"`,
`"cloud-operator"`, `"os-synthesizer"`). Daemon-only verbs (`start`, `stop`, `install-service`) fail
fast with a non-zero semantic error on non-daemons, while cross-compiling toolchains expose
`target-add`, `target-rm`, `target-ls`, `component-add`, and `component-ls`.

_Example:_ `${LIBSCRIPT_HOME}/nodejs/lts` -> `${LIBSCRIPT_HOME}/nodejs/v22.14.0`

## 3. Component Scripts Contract

**Cross-Platform Requirement:** To ensure baseline compatibility across platforms, full Unix Shell
(`.sh`) and Windows Command Prompt (`.cmd`) implementations are **mandatory** for every component
script. Full PowerShell (`.ps1`) implementations may optionally be provided alongside them.

### A. `setup_generic.sh` / `setup.cmd` / `setup.ps1`

1. **Default Method**: The fallback/default installation method must be `libscript_native` (meaning
   native binary download or compilation), NOT `system`.
2. **Version Resolution**: Convert aliases (e.g., `latest`, `lts`) to an exact version number (e.g.,
   `1.22.4`) by querying the official upstream API or release index.
3. **Idempotency**: Check if `${LIBSCRIPT_HOME}/<component>/<exact_version>` exists. If so, exit
   early with a success log.
4. **Isolated Installation**:
   - Download the tarball/zip to a temporary directory.
   - Extract/compile it.
   - Move the final artifacts directly into the `<exact_version>` directory.
5. **Symlinking**: If the requested version was an alias, create or update the symlink:
   `ln -sfn <exact_version> ${LIBSCRIPT_HOME}/<component>/<alias>`. On Windows, use a Junction
   (e.g., `mklink /J`).
6. **No Global State**: Do NOT run `sudo make install`, do NOT extract to `/usr/local/`, and do NOT
   modify system-wide files outside of the `libscript` sandbox.

### B. `env.sh` / `env.cmd` / `env.ps1`

These scripts are responsible for activating the requested version for the current shell session.

1. **Read Requested Version**: Check the component's version variable (e.g., `$PYTHON_VERSION`). If
   unset, default to the most recent installed version or a predefined default (e.g., `latest`).
2. **Path Construction**: Build the path to the isolated bin directory:
   `TARGET_PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/<component>/<resolved_version_or_alias>/bin"`
3. **Path Injection**: Prepend `TARGET_PATH` to the `PATH` environment variable.
4. **Environment Variables**: Set any component-specific variables required (e.g., `GOROOT`,
   `JAVA_HOME`) pointing to the isolated directory.

### C. `vars.schema.json` & `README.md`

1. Update the default value for `<COMPONENT>_INSTALL_METHOD` from `system` to `libscript_native`.
2. Clearly document that `libscript` manages the versions natively.

## 4. Lifecycle Capabilities

To provide a complete version management experience, each component MUST support the following
standardized operations via its internal scripts or CLI interface.

Crucially, **every lifecycle task must respect the `<COMPONENT>_INSTALL_METHOD` environment
variable.** If the method is `libscript_native` (the libscript default), it executes the native
logic defined below. If the method is `system`, `mise`, `asdf`, `pkgx`, or `vfox`, the scripts must
dynamically branch to delegate the lifecycle command to that specific package/version manager.

- **`download`**: Fetches the required artifacts (e.g., tarballs, zips, source code) for the
  specified version and stores them in a local cache (e.g., `${DOWNLOAD_DIR}`). This MUST NOT
  extract or install the software. It strictly supports offline and Ahead-of-Time (AoT) provisioning
  workflows.
- **`install`**: The primary setup routine. It MUST first check if the requested version's artifacts
  exist in the download cache. If present, it skips the network fetch and installs directly from the
  cache. It extracts or compiles artifacts into the isolated version directory.
- **`ls`**: Lists all locally installed versions. For `libscript_native`, it inspects the
  `${LIBSCRIPT_HOME}/<component>/` directory, indicating aliases and the active version. For
  delegates like `mise`/`asdf`/`pkgx`/`vfox`, it delegates to their respective list commands (e.g.,
  `mise ls <comp>`).
- **`ls-remote`**: Queries the official upstream API or release index to list available versions
  that can be downloaded and installed. For delegates, it calls commands like `mise ls-remote` or
  `vfox ls-remote`.
- **`use`**: Activates a specific version by updating the `default` symlink and atomically
  synchronizing executable links in `${LIBSCRIPT_HOME}/bin` (`O(1)` lookup via
  `libscript_sync_active_bins`) or resolving workspace pins (`.libscript-version`, `.nvmrc`,
  `.python-version`, `rust-toolchain.toml` via `libscript resolve-env`).
- **`status`**: Checks installation state (and daemon health when `"service-daemon"` is declared).
- **`uninstall`**: Completely removes the installed version
  (`${LIBSCRIPT_HOME}/<component>/<exact_version>`) and prunes orphaned shims from
  `${LIBSCRIPT_HOME}/bin` (`libscript_prune_active_bins`).
- **Cross-Toolchain Sub-Artifacts (`target-add`, `target-rm`, `target-ls`, `component-add`,
  `component-ls`)**: Supported on multi-target compiler toolchains (such as `_lib/languages/rust`)
  to manage cross-compilation sysroots and tooling components inside the active version prefix.
- **Daemon Verbs (`start`, `stop`, `restart`, `logs`, `install-service`, `uninstall-service` —
  `"service-daemon"` Only)**: Components declaring `"service-daemon"` in `manifest.json` implement
  service supervision (`systemd`, `launchd`, `openrc`, `smf`, Windows Services) via
  `service.{sh,cmd}`. Pure libraries, compilers, and CLI tools MUST NOT include no-op
  `service.{sh,cmd}` stubs and fail fast with exit code `69` (`EX_UNAVAILABLE`) if daemon verbs are
  invoked.

## 5. Alternative Installation Methods & Overrides

While `libscript` must default to its native installation method, it maintains strict compatibility
with existing ecosystem tools.

Global defaults are driven by the **`LIBSCRIPT_DEFAULT_INSTALL_METHOD`** environment variable, which
defaults to `libscript_native`.

Components dynamically evaluate their method fallback sequence as follows:
`<COMPONENT>_INSTALL_METHOD` -> `LIBSCRIPT_DEFAULT_INSTALL_METHOD` -> `libscript_native`

Supported methods:

- **`libscript_native`**: (Default) The libscript_native isolated version manager logic detailed in
  this document.
- **`from-source`**: Compiles the component from verified source code via
  `_lib/_common/source_builder.{sh,cmd}` using either the default platform C toolchain
  (`--toolchain=default`) or a specified C/C++ compiler
  (`--toolchain=gcc|clang|tcc|edgcpp|custom-cc` or `--custom-cc=/path/to/cc`), staging into
  `${LIBSCRIPT_HOME}/<component>/<version>[-<cc>]/` and writing `build-metrics.json`.
- **`system` / `pkg_mgr:<pm>`**: Defers to the OS-level or explicitly requested package manager
  (`--pkg-mgr=<pm>` / `LIBSCRIPT_PKG_MGR=<pm>`, e.g., `apt-get`, `apk`, `dnf`, `brew`, `winget`,
  `choco`, `scoop`, `nix`, `spack`, `vcpkg`), auto-bootstrapping `_lib/package-managers/<pm>` if not
  yet installed.

## 6. Exceptions & Pragmatic Overrides

While `libscript_native` is the strict standard, exceptions are permitted for tools with profound OS
integration or prohibitive compilation requirements:

- **C / C++ (GCC / Clang)**: Default `INSTALL_METHOD` remains `system`. Due to tight coupling with
  OS headers, standard libraries (like `glibc`), and the extreme complexity of distributing
  universal pre-compiled binaries for systems-level toolchains, relying on the OS package manager
  (`apt`, `brew`, `apk`) is the only pragmatic approach for base compilation toolchains.
- **Python Ecosystem CLI Tools (e.g., `xpk`, `huggingface-cli`)**: These are not standalone compiled
  binaries but rather Python packages that rely entirely on `pip` and virtual environments (`venv`)
  for their dependencies and execution context. They inherently use an alternative isolation
  mechanism (the virtual environment) and do not fit the pure binary extraction model. Their
  `INSTALL_METHOD` effectively delegates to Python package managers.

---

## 7. Dual-Layer Component Lifecycle Hook Contract (`hooks/<action>.{sh,cmd}`)

Stateful daemons and multi-tenant engines expose an optional `hooks/` directory dispatched via
`_lib/_common/hooks.sh` and `_lib/_common/hooks.cmd`
(`libscript_exec_hook <component> <hook> [args...]`).

### 7.1 Physical Instance Hooks

Manage the physical daemon instance and its data directory:

1. **`configure`**: Renders configuration templates via `_lib/_common/envsubst_safe.{sh,cmd}`,
   accepting `--role <standalone|leader|follower|arbiter>`, `--sysroot <path>`, and
   `--secrets-file <fifo_or_path>` (for zero-env-leak secret streaming).
2. **`probe <startup|liveness|readiness> [--remote-host <host>]`**:
   - Exit `0`: Healthy / Ready to serve traffic (and replication lag within threshold).
   - Exit `1`: Starting / Degraded / Not Ready.
   - Exit `2`: Unhealthy / Deadlocked / Failed.
3. **`announce`**: Emits deterministic JSON to stdout:
   `{"component":"postgres","endpoints":[{"port":5432,"protocol":"tcp","visibility":"internal","probe":"pg_isready"}]}`.
4. **`log_stream`**: Emits JSON listing active log files, journald/SMF/EventLog identifiers, and
   format (`json`, `clf`, `syslog`, `postgres`).
5. **`metrics`**: Emits JSON specifying Prometheus/OpenTelemetry scrape port, path (`/metrics`,
   `/stub_status`), and exporter status.
6. **`backup <dest_dir>` & `restore <src_dir>`**: Produces and restores full-instance snapshots with
   a `.sha256` manifest.
7. **`upgrade <old_ver> <new_ver>` & `rollback <old_ver> <new_ver>`**: Performs data directory
   migrations (`pg_upgrade`) and atomic rollback on failure.
8. **`maintenance`**: Runs idempotent periodic housekeeping (`VACUUM (ANALYZE)`, WAL pruning, log
   rotation).

### 7.2 Logical Multi-Tenant Hooks

Components with `"multitenant": true` in `manifest.json` (PostgreSQL, MySQL, MariaDB, MongoDB,
Redis, Valkey, Meilisearch, Nginx, Caddy, HTTPD, IIS) expose tenant-scoped hooks:

1. **`provision_tenant --tenant <id> [--db-name <db>] [--db-user <user>] [--server-name <fqdn>]`**:
   Idempotently verifies whether the tenant schema, user, keyspace, or
   `# BEGIN libscript-managed: <tenant>` vhost block exists and creates it only if missing. Safely
   bypasses local physical mutations when `LIBSCRIPT_REMOTE_STRATEGY=remote`.
2. **`deprovision_tenant --tenant <id>`**: Removes only the specified tenant's schema or virtual
   host block while leaving the shared physical engine running for co-tenant stacks.
3. **`backup_tenant --tenant <id> <dest_dir>` & `restore_tenant --tenant <id> <src_dir>`**: Exports
   and restores tenant-isolated logical dumps without affecting neighboring tenants.

---

## 8. Scaffolding a New Version Manager Component (`scaffold` / `new-component`)

To eliminate boilerplate when creating a new component-package-manager that satisfies every contract
in this specification (canonical `THIS_FILE` header, `STACK` recursion guard, `.sh`/`.cmd` parity,
`manifest.json`, `vars.schema.json`, `README.md` markers, and optional `hooks/`), use the built-in
scaffolder:

- **Interactive Wizard (for human maintainers):**
  ```sh
  ./libscript.sh scaffold
  # or on Windows:
  .\libscript.cmd scaffold
  ```
- **Non-Interactive JSON Specification (validated by `component-scaffold.schema.json`):**
  ```sh
  ./libscript.sh scaffold --from-json=my-component.scaffold.json
  ```
- **Non-Interactive CLI Flag Invocation:**
  ```sh
  ./libscript.sh scaffold \
    --non-interactive \
    --name=zoxide \
    --category=utilities \
    --description="A smarter cd command inspired by z and autojump." \
    --github-repo=ajeetdsouza/zoxide \
    --version-scheme=github-release \
    --os=all
  ```
