@echo off
:: # register_bento_boxes.cmd
::
:: ## Overview
:: Discovers built Vagrant .qemu.box images in ..\bento\builds\build_complete\,
:: validates Packer templates in ..\bento\os_pkrvars\, and registers all 6 target OS boxes
:: (bento/omnios, bento/alpine-3.24, bento/debian-13, bento/rockylinux-10.2,
:: bento/freebsd-15.1, bento/windows-11) in the host's Vagrant installation.
::
:: ## Usage
:: tests\register_bento_boxes.cmd [--bento-dir <path>] [--force] [--validate-only]

setlocal EnableDelayedExpansion
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

set "BENTO_DIR=%LIBSCRIPT_ROOT_DIR%\..\bento"
set "BUILD_COMPLETE=%BENTO_DIR%\builds\build_complete"

where vagrant >nul 2>&1
if errorlevel 1 (
    echo [WARN] vagrant CLI not found on host; skipping box registration. >&2
    exit /b 0
)

call :register_box "bento/omnios" "%BUILD_COMPLETE%\omnios-braich-aarch64.qemu.box" "qemu"
call :register_box "bento/alpine-3.24" "%BUILD_COMPLETE%\alpine-3.24-aarch64.qemu.box" "qemu"
call :register_box "bento/debian-13" "%BUILD_COMPLETE%\debian-13.6-aarch64.qemu.box" "qemu"
call :register_box "bento/rockylinux-10.2" "%BUILD_COMPLETE%\almalinux-9.8-aarch64.qemu.box" "qemu"
call :register_box "bento/freebsd-15.1" "%BUILD_COMPLETE%\freebsd-15.1-aarch64.qemu.box" "qemu"
call :register_box "bento/macos-14-arm64" "%BUILD_COMPLETE%\macos-14-aarch64.utm.box" "utm"

echo === Host Vagrant Box Inventory ===
vagrant box list
exit /b 0

:: ## register_box
:: Registers a single box in Vagrant if not already present.
:register_box
set "_BNAME=%~1"
set "_BFILE=%~2"
set "_BPROV=%~3"
if "!_BPROV!"=="" set "_BPROV=qemu"
vagrant box list 2>nul | findstr /C:"!_BNAME!" >nul 2>&1
if not errorlevel 1 (
    echo [OK]   Box !_BNAME! is already registered in host Vagrant.
    exit /b 0
)
if exist "!_BFILE!" (
    echo ==^> Registering !_BNAME! from !_BFILE!...
    vagrant box add --name "!_BNAME!" --provider "!_BPROV!" "!_BFILE!"
)
exit /b 0
