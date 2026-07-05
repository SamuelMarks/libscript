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

**Aliases via Symlinks:** When a user requests an alias (like `lts`, `latest`, `stable`, or `beta`),
the setup script must resolve the exact version, install it to its exact version directory, and then
create a symlink for the alias pointing to that directory.

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
- **`use`**: Activates a specific version for the environment. This may involve updating a global
  `default` symlink or writing to a `.libscript-version` file to ensure the shell picks up the
  requested version across sessions.
- **`start`**: Executes the component. For services, this runs the daemon process; for languages, it
  might start a REPL or a development server if applicable.
- **`stop`**: Safely terminates the running instance of the component.
- **`install-service`**: Registers the component as a persistent background service using the
  OS-native init system (e.g., `systemd`, `launchd`, or Windows Services).
- **`uninstall-service`**: Stops the daemon if running and safely unregisters/removes it from the
  host OS.
- **`uninstall`**: Completely removes the installed version. For `libscript_native`, it removes the
  isolated directory (`${LIBSCRIPT_HOME}/<component>/<exact_version>`) and associated symlinks.

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
- **`system`**: Defers to the OS-level package manager (e.g., `apt`, `brew`, `winget`). Disables
  strict version isolation.

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
