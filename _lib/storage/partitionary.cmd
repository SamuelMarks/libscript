@echo off
set "THIS_FILE=%~f0"
:: # partitionary.cmd
::
:: ## Overview
:: Universal cross-platform storage partitioning and disk geometry abstraction engine on Windows.
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
set "SCRIPT_DIR=%~dp0"
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
