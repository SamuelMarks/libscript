@echo off
:: # grub_multiboot.cmd
::
:: ## Overview
:: Generates GRUB2 configuration blocks for chainloading multiple operating systems.
:: Synthesizes multiboot entries for Linux (direct initrd), FreeBSD (loader.efi chainload),
:: and illumos (bootx64.efi multiboot2).
::
:: ## Usage
::   ./_lib/bootloaders/grub_multiboot.cmd [output_cfg]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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



if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [output_cfg]
exit /b 0

:: ## main
:: Executes the primary orchestration workflow for this script.
:main

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "!SCRIPT_DIR!grub_multiboot.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "!SCRIPT_DIR!grub_multiboot.sh" %*
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system. >&2
exit /b 86
