# Dependency Management

## Purpose
This document explains how LibScript abstracts native OS package managers (`apt`, `apk`, `dnf`, `brew`, `pacman`, `choco`, `winget`) to achieve write-once, run-anywhere dependency resolution.

## What Makes This Interesting?
Handling dependencies across Alpine, Debian, RHEL, Arch, macOS, and Windows usually requires massive lookup tables or dedicated agents. LibScript solves this purely in shell using a unified mapping layer (`pkg_mapper.sh`) and a dynamic executor (`pkg_mgr.sh`). It intelligently falls back to building from source or grabbing static binaries if the native package manager is unavailable or missing a package.

## The Resolution Lifecycle
1. **Request**: A component script calls `depends libssl-dev jq curl`.
2. **Detection**: `os_info.sh` identifies the host environment.
3. **Mapping**: `pkg_mapper.sh` intercepts the request. It knows that `libssl-dev` on Debian is called `openssl-dev` on Alpine and `openssl-devel` on RHEL.
4. **Validation**: The system queries the local package database to see if the mapped package is already installed, ensuring idempotency and speed.
5. **Execution**: If missing, `pkg_mgr.sh` invokes the native package manager non-interactively to install it.

## Declarative Stack Dependencies (`libscript.json`)
Beyond OS-level dependencies, LibScript handles macro-level stack dependencies via `libscript.json`. 
Users can define an entire infrastructure stack (e.g., Postgres, Redis, Python, and an App). 
Running `./libscript.sh install-deps` will:
1. Parse the JSON using `jq`.
2. Execute parallel downloads for all required components (using `aria2` if available).
3. Sequentially install and configure the components based on their priority tiers.

## Component-Level Dependencies
Applications within LibScript can natively declare dependencies on other LibScript components using their `vars.schema.json` schema.

By flagging a variable with `"is_libscript_dependency": true`, the global installer dynamically evaluates it before the component's internal `setup.sh`/`setup.cmd` ever runs.

```json
{
  "properties": {
    "WORDPRESS_DB": {
      "is_libscript_dependency": true,
      "default": "mariadb",
      "enum": ["mariadb", "postgres"],
      "description": "Database backend to use"
    }
  }
}
```

### Resolution Strategies
Dependencies are resolved through an auto-generated strategy property (`--<DEP>_STRATEGY=`), giving operators maximum flexibility over how components are satisfied.

- **`reuse` (Default):** The framework checks if the dependency is already installed globally or locally. If found, it skips installation and safely reuses it (e.g., using an existing PostgreSQL instance to create a new database).
- **`install-alongside`:** Forces a local, isolated installation of the dependency alongside any globally existing ones.
- **`overwrite` / `upgrade` / `downgrade`:** Safely uninstalls the existing target and installs the new version in its place.

These dependency inputs and strategy toggles are seamlessly bridged across all interfaces:
- **Interactive Bash/Cmd Wizards:** Evaluated directly via arguments (`--WORDPRESS_DB_STRATEGY=install-alongside`) or auto-injected environment variables.
- **Native GUI Wizards (MSI/InnoSetup):** The generator layer (`package_as`) maps these schema endpoints to interactive dropdowns and installation stages within the native wizard.

## Feature Enumeration
- Automatic package name translation across distributions.
- Idempotent execution (skips if installed).
- Native schema-driven dependency strategies (`reuse`, `overwrite`).
- Parallel downloads for complex component trees.
- Graceful fallbacks for Windows (`winget`, `choco`, or direct binary fetch).
