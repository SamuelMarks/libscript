@echo off
:: # assemble.cmd
::
:: ## Overview
:: Orchestrates full T3 DOS distribution assembly (base -> dpmi -> network -> config -> filesystem) on Windows.
::
:: ## Usage
:: synthesis\distro\dos\assemble.cmd [sysroot_dir] [output_disk]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_ROOT_DIR%\build\dos-sysroot"
set "OUT_DISK=%~2"
if "!OUT_DISK!"=="" set "OUT_DISK=!SYSROOT!.disk.img"
set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT!"

for %%S in (base dpmi network config) do (
    set "STACK="
    call "!SCRIPT_DIR!\%%S.cmd" "!SYSROOT!"
    if errorlevel 1 exit /b 1
)
set "STACK="
call "!SCRIPT_DIR!\filesystem.cmd" "!SYSROOT!" "!OUT_DISK!"
exit /b !errorlevel!
