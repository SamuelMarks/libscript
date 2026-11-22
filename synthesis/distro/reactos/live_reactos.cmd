@echo off
:: # live_reactos.cmd
::
:: ## Overview
:: Windows companion for live ReactOS ISO/USB image synthesis.
:: Delegates to WSL or POSIX sh when available, or exits with code 86 per Option A proforma rules.
::
:: ## Usage
:: synthesis\distro\reactos\live_reactos.cmd [output_iso_or_img] [build_dir]

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

set "OUTPUT_PATH=%~1"
set "BUILD_DIR=%~2"
if "!OUTPUT_PATH!"=="" set "OUTPUT_PATH=!LIBSCRIPT_ROOT_DIR!\build\msi-reactos-live.iso"
if "!BUILD_DIR!"=="" set "BUILD_DIR=!LIBSCRIPT_ROOT_DIR!\build\live-reactos"

where sh >nul 2>&1
if not errorlevel 1 (
    sh "!SCRIPT_DIR!\live_reactos.sh" "!OUTPUT_PATH!" "!BUILD_DIR!"
    exit /b !errorlevel!
)
where wsl >nul 2>&1
if not errorlevel 1 (
    wsl sh -c "./synthesis/distro/reactos/live_reactos.sh"
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell ^(sh or wsl^) found on this Windows system to repack El Torito live media. >&2
exit /b 86
