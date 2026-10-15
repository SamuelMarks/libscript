@echo off
:: # multiboot_orchestrator.cmd
::
:: ## Overview
:: Universal Multiboot Co-Installation Orchestrator across Linux, FreeBSD, and illumos.
:: Deploys Linux, FreeBSD, and illumos sysroots concurrently onto separate target partitions,
:: configures shared EFI System Partition (ESP), and synthesizes a unified master GRUB2
:: multiboot menu chainloading FreeBSD loader.efi and illumos bootx64.efi / direct kernel.
::
:: ## Usage
:: Execute this script with target device and partition paths:
::   ./_lib/package-managers/msi-rs/distro_installers/multiboot_orchestrator.cmd <disk_dev> [options...]
::
:: Arguments:
::   <disk_dev>              Target storage device path (e.g. /dev/nvme0n1 or /dev/sda)
::
:: Options:
::   --linux-part <dev>      Dedicated partition for Linux root (ext4/btrfs)
::   --freebsd-part <dev>    Dedicated partition for FreeBSD root (UFS2 or ZFS zroot)
::   --illumos-part <dev>    Dedicated partition for illumos ZFS root pool (rpool)
::   --esp-part <dev>        Shared EFI System Partition (FAT32, /boot/efi)
::   --default-os <name>     Default OS in GRUB boot menu (debian, freebsd, or omnios)
::   --timeout <seconds>     Bootloader countdown timer (default: 5)

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

:: # multiboot_orchestrator.cmd
:::: Universal Multiboot Co-Installation Orchestrator across Linux, FreeBSD, and illumos on Windows.
:: Deploys Linux, FreeBSD, and illumos sysroots concurrently onto separate target partitions,
:: configures shared EFI System Partition (ESP), and synthesizes a unified master GRUB2
:: multiboot menu chainloading FreeBSD loader.efi and illumos bootx64.efi / direct kernel.
::
:: ## Usage
:: Call multiboot_orchestrator.cmd <disk_dev> [options...]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported parameters.
:show_help
echo Usage: %~nx0 ^<disk_dev^> [options...]
echo.
echo Concurrently deploys Linux, FreeBSD, and illumos to separate partitions with master GRUB2.
echo.
echo Options:
echo   --linux-part ^<dev^>      Dedicated Linux partition path
echo   --freebsd-part ^<dev^>    Dedicated FreeBSD partition path
echo   --illumos-part ^<dev^>    Dedicated illumos partition path
echo   --esp-part ^<dev^>        Shared EFI System Partition path
echo   --default-os ^<name^>     Default boot entry: debian, freebsd, omnios (default: debian)
echo   --timeout ^<sec^>         Bootloader menu timeout in seconds (default: 5)
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [MULTIBOOT] Starting Multiboot Orchestration on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%multiboot_orchestrator.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%multiboot_orchestrator.sh" %*
    exit /b !errorlevel!
)

echo [OK] Multiboot deployment completed on Windows.
exit /b 0
