@echo off
:: # reactos_distro.cmd
::
:: ## Overview
:: Unified CLI entrypoint to synthesize and package a ReactOS distribution profile on Windows.
::
:: ## Usage
:: synthesis\formats\reactos_distro.cmd --format <iso|qcow2|box|raw|vhd|vmdk> --profile <path> [--output <path>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

set "FORMAT=iso"
set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\desktop-classic-i686.json"
set "OUTPUT="
set "SIZE_GIB=8"
set "SYSROOT="
goto :parse_args

:: ## parse_args
:: Parses CLI options for reactos_distro.cmd.
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="-o" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="--size" ( set "SIZE_GIB=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="--sysroot" ( set "SYSROOT=%~2" & shift & shift & goto :parse_args )
if /I "%~1"=="--from-source" ( set "REACTOS_BUILD_FROM_SOURCE=1" & shift & goto :parse_args )
if /I "%~1"=="--bake-qemu" ( set "REACTOS_QEMU_BAKE=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Runs distribution assembly and dispatches to the requested exporter.
:args_done
for %%F in ("!PROFILE!") do set "PNAME=%%~nF"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot-!PNAME!"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\reactos\assemble.cmd" "!PROFILE!" "!SYSROOT!"
if errorlevel 1 exit /b !errorlevel!

if /I "!FORMAT!"=="iso" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\iso\reactos-!PNAME!.iso"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_iso.cmd" "!SYSROOT!" "!OUTPUT!"
    exit /b !errorlevel!
)
if /I "!FORMAT!"=="raw" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\raw\reactos-!PNAME!.raw"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_raw.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!"
    exit /b !errorlevel!
)
if /I "!FORMAT!"=="qcow2" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\qemu\reactos-!PNAME!.qcow2"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_qcow2.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!"
    exit /b !errorlevel!
)
if /I "!FORMAT!"=="vhd" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\hyperv\reactos-!PNAME!.vhd"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_vhd.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!"
    exit /b !errorlevel!
)
if /I "!FORMAT!"=="vmdk" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\vmware\reactos-!PNAME!.vmdk"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_vmdk.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!"
    exit /b !errorlevel!
)
if /I "!FORMAT!"=="box" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\vagrant\reactos-!PNAME!.box"
    set "_QTMP=!OUTPUT!.qcow2.tmp"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_qcow2.cmd" "!SYSROOT!" "!_QTMP!" "!SIZE_GIB!"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_vagrant_box.cmd" "!_QTMP!" "!OUTPUT!" "qemu"
    del /f /q "!_QTMP!" "!_QTMP!.stamp" >nul 2>&1
    exit /b 0
)

echo [ERROR] Unsupported ReactOS packaging format: !FORMAT! >&2
exit /b 1

:: ## show_help
:: Displays usage instructions for reactos_distro.cmd.
:show_help
echo Usage: %~nx0 --format ^<iso^|qcow2^|box^|raw^|vhd^|vmdk^> --profile ^<path^> [--output ^<path^>]
exit /b 0
