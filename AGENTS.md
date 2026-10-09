# Agent & Skill Engineering Standards (`AGENTS.md` / `SKILLS.md`)

This guide specifies the operational rules, coding standards, architectural invariants, and
execution conventions that all automated agents, language model assistants, and procedural skills
must strictly follow when modifying or extending the LibScript codebase.

---

## 🎯 1. Core Operating Principles

1. **Autonomous, Zero-Dependency Substrate**: LibScript is built on zero-dependency POSIX shell and
   Windows batch scripts. Never introduce dependencies on external interpreters (Python, Ruby, Perl,
   Node.js) for core orchestration or installation tasks.
2. **Every Component is Reusable**: Everything in `_lib/` is a decentralized, standalone package
   manager. Never reinvent functionality or introduce one-off installation scripts. Compose from
   existing components.
3. **Dual-Platform Parity**: Linux/BSD/macOS and Windows are first-class peers. Every `.sh` script
   must have an identical, behavior-matched `.cmd` equivalent.
4. **Strict Idempotency**: Running any script twice must produce the exact same outcome without
   failing or corrupting state.
5. **100% Documentation Coverage**: Every script and shell function must feature structured
   docstrings for automated doc extractors.
6. **Zero External Git Operations**: Never run `git push`. All git operations are local-only.

---

## 🏛️ 2. Component Reusability & Strict Modularity

LibScript enforces a **Zero-Tolerance Policy for Ad-Hoc Scripts**. Agents must strictly adhere to
the decentralized, reusable architecture.

### 🚫 Zero-Tolerance for Ad-Hoc Installers

**NEVER** create standalone installation scripts (e.g., `install_nginx.sh`, `setup_tools.ps1`,
`build_deps.sh`) in `devtools/`, `tests/`, or the root directory. If a new tool, language, or
service is required, you **MUST** create a fully compliant, standalone Tier 1 recipe in
`_lib/<category>/<component>/`.

**WRONG (Anti-Pattern)**: Writing loose scripts that invoke OS package managers directly:

```powershell
# BAD: Do NOT do this
winget install Microsoft.VisualStudio.2022.BuildTools
winget install Git.Git
```

**RIGHT (The Only Acceptable Way)**: Depend on the canonical LibScript components (e.g.,
`_lib/languages/c`, `_lib/toolchains/cmake`). If the component does not exist, author it as a new
Tier 1 recipe.

### 🧱 Component Granularity Rule (No "Fat" Recipes)

Every recipe must manage exactly **one** specific piece of software. Never create "fat" components
that install multiple tools (e.g., no `lamp-stack` component that installs Apache, MySQL, and PHP
together).

- Each tool MUST be its own independent, atomic recipe (`_lib/web-servers/apache`,
  `_lib/databases/mysql`).
- Compositions must happen dynamically via `manifest.json` dependencies or Tier 2 execution plans,
  never by piling logic into a single Tier 1 setup script.

### 📜 The Strict Version Manager Contract

Every software recipe in `_lib/` acts as an autonomous version manager and MUST expose the standard
entry points, adhering completely to the lifecycle capabilities defined in
`WHAT_A_VERSION_MANAGER_SHOULD_LOOK_LIKE.md`:

- `cli.sh` / `cli.cmd`: The primary router supporting mandatory verbs: `download`, `install`, `ls`,
  `ls-remote`, `use`, `start`, `stop`, `install-service`, `uninstall-service`, and `uninstall`.
- `setup.sh` / `setup.cmd`: Installation entry point, managing offline caching and delegating to
  `_lib/_common/setup_base.*`.
- `env.sh` / `env.cmd`: Exports strictly isolated paths without polluting global shell profiles.
- `service.sh` / `service.cmd`: Service daemon management (systemd, launchd, Windows Service).
- `test.sh` / `test.cmd`: Component-specific smoke tests and binary verification.

### 🔍 Pre-Implementation Verification

Before creating a new component or script, agents **MUST** use search tools (`grep_search`, `glob`)
to thoroughly audit the `_lib/` directory. Prove there is no existing component that can be extended
or reused before introducing new code.

### Dependency Resolution

To consume or require other components from within a recipe:

- **POSIX `/bin/sh`**:
  ```sh
  libscript_depends "cmake" "ninja" "c"
  ```
  Or invoke the root orchestrator directly:
  ```sh
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install c latest
  ```
- **Windows Batch (`.cmd`)**:
  ```cmd
  call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install c latest
  ```
- **Artifact Downloads**: Use `libscript_download <url> <dest> [sha256]` provided by
  `_lib/_common/pkg_mgr.sh` and `_lib/_common/pkg_mgr.cmd`.

---

## 📜 3. POSIX `/bin/sh` Standards & The `THIS_FILE=` Dance

All shell scripts must be strictly POSIX compliant (`#!/bin/sh`), never Bash (`#!/bin/bash`).

### Canonical Script Header Template

Every `.sh` script must begin with this exact structure within the first 30 lines:

```sh
#!/bin/sh
# ## Overview
# Concise description of what this script accomplishes.
#
# ## Usage
# ./path/to/script.sh [args]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
```

### Key Invariants for POSIX Shell:

- `set -feu`: Fail on unset variables (`-u`), exit on command failure (`-e`), disable glob expansion
  on empty match (`-f`).
- `STACK` Recursion Guard: Prevents infinite recursion when sourcing common scripts or circular
  dependencies.
- `LIBSCRIPT_ROOT_DIR` Resolution: Ascends the filesystem looking for `libscript.sh`.
- No `eval`: The `audit_standards.sh` linter rejects `eval` unless tagged with
  `# libscript-allow-eval` for authorized shims.

---

## 🪟 4. Windows Batch (`.cmd`) Standards

Every `.sh` script in the repository must have a corresponding `.cmd` (or `.bat`) script located in
the same directory.

### Canonical Batch Header Template

Every `.cmd` script must begin with this exact structure within the first 25 lines:

```cmd
@echo off
:: # script_name.cmd
::
:: ## Overview
:: Concise description of what this batch script accomplishes.
::
:: ## Usage
:: script_name.cmd [args]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
```

---

## 🔁 5. Idempotency Invariants

Scripts and commands must be safe to rerun repeatedly without failing or mutating already-configured
state.

1. **Directory Creation**:
   - POSIX: Always `mkdir -p <dir>`. Bare `mkdir <dir>` without `-p` is rejected by the linter.
   - Batch: Always check before creating:
     ```cmd
     if not exist "path	o\dir" mkdir "path	o\dir"
     ```
2. **Symlinks**:
   - POSIX: Always `ln -sf <target> <link>`. Bare `ln -s` is rejected by the linter.
3. **Installation & Early Exit**:
   - Version managers must check if `${LIBSCRIPT_HOME}/<component>/<exact_version>` or the target
     executable exists before downloading:
     ```sh
     if [ -x "${TARGET_DIR}/bin/${BIN_NAME}" ]; then
       log_info "${COMPONENT} ${VERSION} is already installed at ${TARGET_DIR}."
       exit 0
     fi
     ```
   - Windows batch scripts must similarly check:
     ```cmd
     if exist "%TARGET_DIR%\bin\%BIN_NAME%.exe" (
         echo [INFO] %COMPONENT% %VERSION% is already installed.
         exit /b 0
     )
     ```

---

## 📚 6. 100% Documentation Coverage Requirements

LibScript validates 100% documentation coverage statically via:

- `devtools/audit/audit_standards.sh`
- `devtools/audit/doc_coverage.sh`

### Header Docstrings

Within the first 30 lines of every `.sh`, `.cmd`, `.bat`, and `.ps1` file:

```text
## Overview
A clear, 1-2 sentence description of the file's purpose.

## Usage
Syntax examples showing how the script is invoked.
```

### Function & Subroutine Docstrings

Every function in a `.sh` file and every label/subroutine called in a `.cmd` file must be preceded
by a docblock:

```sh
# ## configure_service
# Configures the target service unit and sets appropriate permissions.
configure_service() {
  ...
}
```

```cmd
:: ## configure_service
:: Configures the target service unit and sets appropriate permissions.
:configure_service
  ...
```

### Schema Coverage

All `*.schema.json` files must provide a non-empty `"description"` for every property.

---

## 🛡️ 7. Safety & Remote Invariants

1. **NEVER Run `git push`**: The repository is managed with local-only workflows. `git push`
   triggers an immediate standards violation and hard failure in automated test runners.
2. **Option A Hard Fail**: Proforma virtualization/chroot scripts (`mount_target_vfs.cmd`,
   `provision_disk.cmd`, etc.) on unsupported architectures must exit with code `86`.
3. **Recipe Boundaries**: Tier 1 leaf packages (`_lib/*/*`) must not invoke storage/kernel
   partitioning primitives (`mount`, `umount`, `fdisk`, `mkfs`, `cryptsetup`). Such actions belong
   strictly to Tier 2 image synthesizers.

---

## 🧪 8. Pre-Commit Verification Workflow

Before proposing or finalizing changes, execute the audit suite:

```sh
# Audit standards across all staged files
./devtools/audit/audit_standards.sh --staged

# Check documentation coverage
./devtools/audit/doc_coverage.sh

# Run component test suites
./make.sh test_component <component_name>
```
