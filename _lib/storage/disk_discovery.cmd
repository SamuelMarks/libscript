@echo off
set "THIS_FILE=%~f0"
:: # disk_discovery.cmd
::
:: ## Overview
:: Cross-platform disk device discovery engine for Windows environments.
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
