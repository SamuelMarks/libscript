# Architecture

LibScript is designed around a composable, shell-script-first architecture. It avoids complex external dependencies (like Python or Ruby) for its core engine, relying purely on POSIX `sh` (and Windows `cmd.exe`/`powershell` or MS-DOS `COMMAND.COM`) to bootstrap systems.

## Component Structure

Every component in LibScript (found in `_lib/` or `app/`) follows a predictable directory structure:

```
_lib/_toolchain/rust/
├── cli.sh              # CLI entrypoint for this specific component
├── cli.cmd             # Windows CLI entrypoint
├── cli.bat             # (Optional) MS-DOS CLI entrypoint
├── env.sh              # Exports environment variables/defaults
├── setup.sh            # Main Unix entrypoint for installation
├── setup_generic.sh    # Cross-platform fallback setup logic
├── setup_debian.sh     # (Optional) OS-specific setup logic
├── setup.cmd           # Windows fallback setup logic
├── setup.bat           # (Optional) MS-DOS fallback setup logic
├── setup_win.ps1       # Windows PowerShell setup logic
├── test.sh             # Verification script (Unix)
├── test.cmd            # Verification script (Windows)
├── test.bat            # (Optional) Verification script (MS-DOS)
└── vars.schema.json    # JSON schema defining configurable parameters
```

## The Execution Lifecycle

1. **Invocation**: A user runs `./libscript.sh <COMMAND> <PACKAGE_NAME> [VERSION] [OPTIONS]` (or `libscript.cmd`, `libscript.bat`). The global dispatcher locates the component and executes its CLI router.
2. **Configuration**: The `cli.sh` parses arguments against `vars.schema.json` and exports them as environment variables.
3. **Setup Resolution**: `cli.sh` calls `setup.sh`.
4. **Environment Loading**: `setup.sh` sources common utilities (e.g., `_lib/_common/os_info.sh`) to detect the OS, distribution, and architecture.
5. **OS Specific Execution**: If an OS-specific script exists (e.g., `setup_debian.sh` or `setup_alpine.sh`), it is executed. Otherwise, it falls back to `setup_generic.sh`.
6. **Dependency Resolution**: Inside the setup scripts, `depends <package>` is called, which delegates to `pkg_mgr.sh` to translate the abstract package name into the OS-native package name and install it via `apt`, `apk`, `dnf`, `brew`, etc.
7. **Verification**: After installation, the user or CI can invoke `test.sh` to verify the installation succeeded and works (e.g., compiling a Hello World program).

## Core Libraries (`_lib/_common/`)

- `os_info.sh`: Identifies the `UNAME`, `TARGET_OS`, `TARGET_ARCH`, and init system (`systemd`, `openrc`).
- `pkg_mgr.sh`: The package manager abstraction layer. Detects the available package manager and executes the correct install commands.
- `pkg_mapper.sh`: Translates generic package names (e.g., `libssl-dev`) into OS-specific names (e.g., `openssl-dev` on Alpine, `openssl-devel` on RHEL).
