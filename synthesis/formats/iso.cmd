@echo off
:: # iso.cmd
:: ## Overview
:: Packages target sysroot or declarative `--profile` into a live bootable ISO 9660 hybrid media image on Windows.
:: ## Usage
:: iso.cmd [--profile <path|preset>] [target_sysroot] [output_iso] [volume_id]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

echo %* | findstr /I /C:"--profile" /C:"-p " >nul 2>&1
if not errorlevel 1 (
    set "STACK="
    call "!SCRIPT_DIR!\_profile_dispatch.cmd" "iso" %*
    exit /b !ERRORLEVEL!
)

call "!LIBSCRIPT_ROOT_DIR!\engine\common\vm_builder.cmd" "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\iso.sh" %*
exit /b !ERRORLEVEL!

:: ## show_help
:: Displays usage instructions for iso.cmd.
:show_help
echo Usage: %~nx0 [--profile ^<path^|preset^>] [target_sysroot] [output_iso] [volume_id]
echo Synthesizes live bootable ISO image.
exit /b 0
