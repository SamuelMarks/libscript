@echo off
:: # context.cmd
::
:: ## Overview
:: Codifies the standard context contract variables and idempotency stamp
:: protocols passed between Tier 2 synthesizers and Tier 1 leaf recipes.
::
:: ## Usage
:: Call this script to initialize and validate standard context variables:
::   call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\context.cmd"

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


IF NOT DEFINED LIBSCRIPT_ROOT_DIR (
    SET "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

IF NOT DEFINED LIBSCRIPT_BUILD_DIR (
    SET "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
)
IF NOT DEFINED LIBSCRIPT_TARGET_SYSROOT (
    SET "LIBSCRIPT_TARGET_SYSROOT=%LIBSCRIPT_BUILD_DIR%\sysroot"
)
IF NOT DEFINED LIBSCRIPT_HOST_ROOT (
    SET "LIBSCRIPT_HOST_ROOT=/tools"
)
IF NOT DEFINED LIBSCRIPT_STAGE (
    SET "LIBSCRIPT_STAGE=stage0"
)
IF NOT DEFINED LIBSCRIPT_TARGET_ARCH (
    SET "LIBSCRIPT_TARGET_ARCH=x86_64"
)
IF NOT DEFINED LIBSCRIPT_TARGET_LIBC (
    SET "LIBSCRIPT_TARGET_LIBC=glibc"
)
IF NOT DEFINED LIBSCRIPT_TARGET_OS (
    SET "LIBSCRIPT_TARGET_OS=linux"
)
IF NOT DEFINED LIBSCRIPT_OFFLINE (
    SET "LIBSCRIPT_OFFLINE=0"
)
IF NOT DEFINED LIBSCRIPT_CACHE_DIR (
    SET "LIBSCRIPT_CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache"
)

SET "LIBSCRIPT_STAMP_DIR=%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps"

if not exist "%LIBSCRIPT_STAMP_DIR%" mkdir "%LIBSCRIPT_STAMP_DIR%"

exit /b 0
