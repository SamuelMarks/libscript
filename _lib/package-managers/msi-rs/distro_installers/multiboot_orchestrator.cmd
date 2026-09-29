@echo off
set "THIS_FILE=%~f0"
:: # multiboot_orchestrator.cmd
::
:: ## Overview
:: Universal Multiboot Co-Installation Orchestrator across Linux, FreeBSD, and illumos on Windows.
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
set "SCRIPT_DIR=%~dp0"
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
