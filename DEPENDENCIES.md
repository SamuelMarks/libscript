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

## Feature Enumeration
- Automatic package name translation across distributions.
- Idempotent execution (skips if installed).
- Parallel downloads for complex component trees.
- Graceful fallbacks for Windows (`winget`, `choco`, or direct binary fetch).
