@echo off
:: # freebsd_raw.cmd
:: ## Overview
:: Packages a FreeBSD target sysroot into a raw GPT disk image on Windows via vm_builder or exits 86 when unsupported.
:: ## Usage
:: freebsd_raw.cmd [--worker=docker|wsl2] [--allow-stub] [target_sysroot] [output_image] [size_gib]

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
    set "OUT_IMG=%~2"
    if "!OUT_IMG!"=="" set "OUT_IMG=!LIBSCRIPT_ROOT_DIR!\build\freebsd.raw"
    for %%F in ("!OUT_IMG!") do set "OUT_DIR=%%~dpF"
    if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
    if exist "!OUT_IMG!.stamp" if exist "!OUT_IMG!" (
        echo [SKIP]     FreeBSD raw image !OUT_IMG! already generated ^(stub^)
        exit /b 0
    )
    echo LibScript FreeBSD Raw Disk Stub> "!OUT_IMG!"
    echo mode=stub> "!OUT_IMG!.stamp"
    exit /b 0
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\vm_builder.cmd" "!LIBSCRIPT_ROOT_DIR!\cli\commands\package_as\freebsd_raw.sh" %*
exit /b !ERRORLEVEL!

:: ## show_help
:: Displays usage instructions for FreeBSD raw image generation.
:show_help
echo Usage: %~nx0 [--worker=docker^|wsl2] [--allow-stub] [target_sysroot] [output_image] [size_gib]
echo Packages FreeBSD sysroot into a raw disk image via vm_builder ^(or exits 86 if unavailable^).
exit /b 0
