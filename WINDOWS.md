# Windows and MS-DOS Support

## Purpose & Current State

**Purpose**: This document details the specific architectural decisions, workarounds, and scripting languages (`.cmd`, `.ps1`, `.bat`) used to support modern Windows and legacy MS-DOS environments. LibScript is a modular, zero-dependency shell-script framework designed for cross-platform software provisioning across Linux, macOS, DOS, and Windows.

**Current State**: Windows and DOS support is a first-class citizen in the ecosystem. The core logic natively utilizes `.cmd` and PowerShell for MSIs, Registry edits, and Path updates, with legacy `.bat` fallbacks for pure DOS environments. Recent advancements have stabilized the automated generation of Windows installers (MSI, InnoSetup, NSIS) directly from component definitions.

## Windows Architecture

Instead of `.sh` files, Windows utilizes `.cmd` (Batch) and `.ps1` (PowerShell) files.

Every component should ideally contain:
- `cli.cmd`: The entrypoint for parameter parsing on Windows.
- `setup.cmd`: A wrapper that handles pre-PowerShell DOS portability hooks and calls the actual setup logic.
- `setup_win.ps1`: The core installation logic written in PowerShell. It handles downloading MSI installers, extracting zip archives, modifying the Windows Registry, and updating the Machine/User `PATH`.
- `test.cmd`: The verification script (e.g., compiling a "Hello World" in C# via `dotnet`).

## MS-DOS Architecture (.bat)

To support MS-DOS and early Windows environments that lack modern `cmd.exe` features (like delayed expansion) or PowerShell, LibScript supports `.bat` file fallbacks:
- `dos_setup_script_deps.bat`: Bootstraps necessary tools (like `curl` and `jq`) onto a bare MS-DOS machine using native `ftp` and pre-compiled 32-bit binaries.
- `libscript.bat`: A global router for DOS that delegates to components without modern command extensions.
- When `libscript.bat` invokes a component, or when `install.bat` runs, they will prioritize `cli.bat` and `setup.bat` if present, falling back to `.cmd` equivalents. This ensures that legacy components remain decoupled and purely DOS-compatible without breaking the modern Windows experience.

## The Global Router

Just like `libscript.sh`, Windows users can use `libscript.cmd` (or `libscript.bat` on DOS) from the root of the repository to list, search, and invoke components.

```cmd
libscript.cmd list
libscript.cmd install rust latest
```

## Known Limitations

- **Package Managers:** Windows does not have a single unified package manager universally available like `apt`. `winget`, `choco`, or `scoop` can be utilized inside `setup_win.ps1` if available, but the primary fallback strategy on Windows is direct download and extraction of pre-compiled binaries.
- **Services:** Systemd and OpenRC do not exist on Windows. For components that run as background services (e.g., Postgres, Valkey), they must be installed as Windows Services using utilities like `sc.exe` or `NSSM` (Non-Sucking Service Manager).
