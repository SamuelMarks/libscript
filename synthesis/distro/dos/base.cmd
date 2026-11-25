@echo off
:: # base.cmd
::
:: ## Overview
:: Stages the selected base DOS kernel and win-cmd-asm utilities into LIBSCRIPT_TARGET_SYSROOT on Windows.
::
:: ## Usage
:: synthesis\distro\dos\base.cmd [sysroot_dir]

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
if not exist "!SYSROOT!" mkdir "!SYSROOT!"
set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT!"
if /I "%LIBSCRIPT_TARGET_OS%"=="msdos" (
    set "MSDOS_VERSION=%LIBSCRIPT_DOS_VERSION%"
    if "!MSDOS_VERSION!"=="" set "MSDOS_VERSION=4.0"
    set "ACTION=install"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\msdos\setup.cmd"
    if errorlevel 1 exit /b 1
) else (
    set "FREEDOS_VERSION=%LIBSCRIPT_DOS_VERSION%"
    if "!FREEDOS_VERSION!"=="" set "FREEDOS_VERSION=1.4"
    set "ACTION=install"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\freedos\setup.cmd"
    if errorlevel 1 exit /b 1
)
set "LIBSCRIPT_IMAGE_BUILD=1"
set "ACTION=install"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\win-cmd-asm\setup.cmd"
exit /b !errorlevel!
