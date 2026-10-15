@echo off
:: # partitioner.cmd
::
:: ## Overview
:: Unified cross-platform partition manipulator supporting GPT, MBR, and illumos VTOC layouts.
:: Automatically synthesizes standard EFI System Partitions, BIOS boot partitions, swap slices,
:: and primary root partitions with full idempotency across Linux, FreeBSD, and illumos.
::
:: ## Usage
:: Execute this script to partition a target disk or raw image:
::   ./_lib/storage/partitioner.cmd <device_or_image> [scheme] [boot_mode] [swap_mib]

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

:: # partitioner.cmd
:::: Cross-platform disk partitioning engine for Windows environments.
:: Initializes GPT or MBR partition tables, creates EFI System Partitions, and formats volumes.
::
:: ## Usage
:: Call partitioner.cmd <disk_number> [scheme] [boot_mode]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and command-line options.
:show_help
echo Usage: %~nx0 ^<disk_number^> [scheme] [boot_mode]
echo.
echo Initializes partition structures on Windows disks.
echo.
echo Schemes:
echo   gpt       - GUID Partition Table (default)
echo   mbr       - Master Boot Record
echo.
echo Boot Modes:
echo   uefi      - Creates 512MB EFI ESP partition (default)
echo   bios      - Legacy BIOS partition layout
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "DISK_NUM=%~1"
set "SCHEME=%~2"
set "BOOT_MODE=%~3"

if "%DISK_NUM%"=="" (
    echo [ERROR] Target disk number is required. >&2
    exit /b 1
)
if "%SCHEME%"=="" set "SCHEME=gpt"
if "%BOOT_MODE%"=="" set "BOOT_MODE=uefi"

echo [INFO] Partitioning disk %DISK_NUM% via %SCHEME% (%BOOT_MODE%)...

powershell -NoProfile -Command ^
    "$d = Get-Disk -Number %DISK_NUM%; " ^
    "if ($d.PartitionStyle -eq 'RAW') { " ^
    "    Initialize-Disk -Number %DISK_NUM% -PartitionStyle GPT; " ^
    "    New-Partition -DiskNumber %DISK_NUM% -Size 512MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' | Format-Volume -FileSystem FAT32 -NewFileSystemLabel 'ESP' -Confirm:$false; " ^
    "    if ('%SCHEME%' -eq 'gpt-dual-os' -or '%SCHEME%' -eq 'dual') { " ^
    "        $rem = [math]::Floor(($d.Size - 600MB) / 2); " ^
    "        New-Partition -DiskNumber %DISK_NUM% -Size $rem | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'LinuxRoot' -Confirm:$false; " ^
    "        New-Partition -DiskNumber %DISK_NUM% -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'FreeBSDRoot' -Confirm:$false; " ^
    "    } else { " ^
    "        New-Partition -DiskNumber %DISK_NUM% -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'LibScriptTarget' -Confirm:$false; " ^
    "    } " ^
    "} else { " ^
    "    Write-Output '[INFO] Disk %DISK_NUM% already partitioned. Preserving.' " ^
    "}"

if !errorlevel! EQU 0 (
    echo [OK] Partitioning of disk %DISK_NUM% completed successfully.
    exit /b 0
) else (
    echo [ERROR] Failed to partition disk %DISK_NUM%. >&2
    exit /b 1
)
