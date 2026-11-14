@echo off
:: # illumos_iso.cmd
:: ## Overview
:: Packages an illumos target sysroot into a bootable ISO image on Windows via vm_builder or exits 86 when unsupported.
:: ## Usage
:: illumos_iso.cmd [--worker=docker|wsl2] [--allow-stub] [target_sysroot] [output_iso]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

if /I "%~1"=="--allow-stub" (
    set "LIBSCRIPT_ALLOW_STUB=1"
    shift
)

if "%LIBSCRIPT_ALLOW_STUB%"=="1" (
    set "OUT_ISO=%~2"
    if "!OUT_ISO!"=="" set "OUT_ISO=!LIBSCRIPT_ROOT_DIR!\build\illumos.iso"
    for %%F in ("!OUT_ISO!") do set "OUT_DIR=%%~dpF"
    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
    if exist "!OUT_ISO!.stamp" if exist "!OUT_ISO!" (
        echo [SKIP]     illumos ISO !OUT_ISO! already synthesized ^(stub^)
        exit /b 0
    )
    echo LibScript illumos ISO Stub> "!OUT_ISO!"
    echo mode=stub> "!OUT_ISO!.stamp"
    exit /b 0
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\vm_builder.cmd" "!LIBSCRIPT_ROOT_DIR!\cli\commands\package_as\illumos_iso.sh" %*
exit /b !ERRORLEVEL!

:: ## show_help
:: Displays usage instructions for illumos ISO generation.
:show_help
echo Usage: %~nx0 [--worker=docker^|wsl2] [--allow-stub] [target_sysroot] [output_iso]
echo Synthesizes illumos bootable ISO via vm_builder ^(or exits 86 if unavailable^).
exit /b 0
