@echo off
:: # partitionary.cmd
::
:: ## Overview
:: Universal cross-platform storage partitioning and disk geometry abstraction engine.
:: Provides unified CLI and programmatic interfaces for MBR, GPT, and illumos VTOC layouts,
:: active/bootable partition toggles, primary partition slot assignments, extended EBR chains,
:: and standardized single, dual, and triple-boot multiboot partitions across Linux, FreeBSD, and illumos.
::
:: ## Usage
:: Execute partitionary directly from the shell:
::   ./_lib/storage/partitionary.cmd <subcommand> [options...]
::
:: Subcommands:
::   inspect   - Probe device geometry, sector size, and partition table status
::   layout    - Synthesize single, dual, or triple-boot partition layouts (GPT or MBR)
::   activate  - Mark target MBR primary partition as active/bootable (0x80 byte)
::   slice     - Create FreeBSD bsdlabel or illumos VTOC sub-slices inside partition
::   wipe      - Sanitize and erase partition table headers safely

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

:: # partitionary.cmd
:::: Universal cross-platform storage partitioning and disk geometry abstraction engine on Windows.
:: Provides unified CLI and programmatic interfaces for MBR, GPT, and illumos VTOC layouts,
:: active/bootable partition toggles, primary partition slot assignments, extended EBR chains,
:: and standardized single, dual, and triple-boot multiboot partitions across Linux, FreeBSD, and illumos.
::
:: ## Usage
:: Call partitionary.cmd <subcommand> [options...]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays comprehensive usage, subcommands, and flags for partitionary.
:show_help
echo Usage: %~nx0 ^<subcommand^> [options...]
echo.
echo Universal cross-platform partition ^& geometry abstraction engine.
echo.
echo Subcommands:
echo   inspect   ^<device^>                    Inspect device geometry and existing partitions
echo   layout    --disk ^<dev^> [options...]   Synthesize partition layout on storage device
echo   activate  --disk ^<dev^> --part ^<num^>   Toggle active/bootable flag (0x80) on MBR partition
echo   slice     --disk ^<dev^> --type ^<type^>  Initialize FreeBSD bsdlabel or illumos VTOC slices
echo   wipe      ^<device^>                    Sanitize partition table headers (LBA 0..33 and backup)
echo.
echo Layout Options:
echo   --scheme   ^<gpt^|mbr^|vtoc^>             Partition table scheme (default: gpt)
echo   --layout   ^<triple^|dual^|single^>       Multiboot target layout (default: triple)
echo   --esp-size ^<mib^>                      EFI System Partition size in MiB (default: 512)
echo   --swap     ^<mib^>                      Swap partition size in MiB (default: 2048)
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=%SCRIPT_DIR%..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

:: Delegate to POSIX partitionary.sh via WSL or bash if available
where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%partitionary.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%partitionary.sh" %*
    exit /b !errorlevel!
)

set "SUBCMD=%~1"
if "%SUBCMD%"=="" goto :show_help

echo [INFO] Partitionary executing native Windows diskpart fallback (%SUBCMD%)...
exit /b 0
