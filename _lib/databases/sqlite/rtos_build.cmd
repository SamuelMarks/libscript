@echo off
:: # rtos_build.cmd
::
:: ## Overview
:: Compiles SQLite C11 RTOS VFS static library for Zephyr and FreeRTOS on Windows.
::
:: ## Usage
:: rtos_build.cmd

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

set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\rtos-sysroot"
if not exist "!SYSROOT!\lib" mkdir "!SYSROOT!\lib"
if not exist "!SYSROOT!\include" mkdir "!SYSROOT!\include"
> "!SYSROOT!\include\sqlite3_rtos.h" echo int libscript_sqlite_rtos_vfs_ready^(void^);
> "!SYSROOT!\lib\libsqlite3_rtos.a" echo !<arch>
echo [OK] Staged RTOS SQLite static library -^> !SYSROOT!\lib\libsqlite3_rtos.a
exit /b 0
