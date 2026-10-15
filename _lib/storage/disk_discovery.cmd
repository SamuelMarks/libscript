@echo off
:: # disk_discovery.cmd
::
:: ## Overview
:: Cross-platform disk device discovery and hardware geometry inspection engine.
:: Detects available physical and virtual storage devices across Linux, FreeBSD, and illumos,
:: analyzes sector sizes, verifies active mount interlocks, and outputs disk metadata.
::
:: ## Usage
:: Execute this script to list or inspect disks:
::   ./_lib/storage/disk_discovery.cmd [--json | --help | --wipe <device>]

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

:: # disk_discovery.cmd
:::: Cross-platform disk device discovery engine for Windows environments.
:: Enumerates physical drives, virtual disks, and volumes with sector sizes and health status.
::
:: ## Usage
:: Call disk_discovery.cmd [--json | --help | --wipe <disk_number>]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and command-line options.
:show_help
echo Usage: %~nx0 [--json ^| --wipe ^<disk_number^>]
echo.
echo Discovers and inspects physical and virtual disks on Windows.
echo.
echo Options:
echo   --json               Output disk information in JSON format.
echo   --wipe ^<disk_num^>    Sanitize partition table of specified disk number.
echo   --help, -h, /?, -?   Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "FORMAT_MODE=table"
set "WIPE_DISK="

if /i "%~1"=="--json" set "FORMAT_MODE=json"
if /i "%~1"=="--wipe" (
    set "WIPE_DISK=%~2"
    goto :do_wipe
)

if "%FORMAT_MODE%"=="json" (
    powershell -NoProfile -Command "Get-Disk | Select-Object Number, FriendlyName, SerialNumber, Size, PartitionStyle, BusType, OperationalStatus | ConvertTo-Json"
    exit /b 0
)

powershell -NoProfile -Command "Get-Disk | Format-Table -AutoSize Number, FriendlyName, @{Label='Size(GB)';Expression={[math]::Round($_.Size/1GB,2)}}, PartitionStyle, BusType, OperationalStatus"
exit /b 0

:: ## do_wipe
:: Executes disk sanitization via PowerShell Clear-Disk.
:do_wipe
if "%WIPE_DISK%"=="" (
    echo [ERROR] Disk number required for --wipe >&2
    exit /b 1
)

echo [INFO] Sanitizing and wiping disk number %WIPE_DISK%...
powershell -NoProfile -Command "Clear-Disk -Number %WIPE_DISK% -RemoveData -RemoveOEM -Confirm:$false"
if !errorlevel! EQU 0 (
    echo [OK] Disk %WIPE_DISK% successfully sanitized.
    exit /b 0
) else (
    echo [ERROR] Failed to wipe disk %WIPE_DISK%. >&2
    exit /b 1
)
