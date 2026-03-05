# Windows and MS-DOS Support

## Purpose
Details how LibScript seamlessly supports modern Windows (via `cmd` and PowerShell) and legacy MS-DOS environments, achieving parity with its Unix counterparts.

## What Makes This Interesting?
Achieving infrastructure-as-code parity on Windows without forcing users into WSL or installing third-party runtimes is notoriously difficult. LibScript solves this by utilizing native `.cmd` files as a routing layer and delegating heavy lifting to PowerShell (`.ps1`), while maintaining a strict `.bat` fallback architecture for true legacy MS-DOS environments.

## Modern Windows Architecture (`.cmd` and `.ps1`)
Instead of `.sh` scripts, Windows components use:
- `cli.cmd`: Parses arguments natively in the Command Prompt.
- `setup.cmd`: Acts as the portability wrapper.
- `setup_win.ps1`: The core execution engine. It handles downloading artifacts, silently installing MSIs, unpacking ZIPs, editing the Windows Registry, and securely updating the User/Machine `PATH`.
- `test.cmd`: Idempotent verification tests.

## Global Routing
The root router `libscript.cmd` behaves exactly like `libscript.sh`.
```cmd
libscript.cmd install python 3.12
libscript.cmd run python 3.12 script.py
```

## Background Services
Since Windows lacks Systemd or OpenRC, LibScript natively translates background daemon configurations into Windows Services. Tools like Valkey or Postgres are installed, configured, and registered natively via standard Windows service utilities (`sc.exe`), controllable via `libscript.cmd start postgres`.

## Legacy MS-DOS Support (`.bat`)
To support environments predating modern `cmd.exe` command extensions or PowerShell, LibScript utilizes `.bat` fallbacks:
- `libscript.bat` prioritizes `cli.bat` and `setup.bat` if they exist.
- `dos_setup_script_deps.bat` uses legacy FTP capabilities to bootstrap standard CLI tools (like `curl` and `jq`) onto raw MS-DOS setups, enabling them to interface with the modern LibScript ecosystem without breaking the mainline `.cmd` features.
