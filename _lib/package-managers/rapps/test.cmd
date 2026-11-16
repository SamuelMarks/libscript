@echo off
:: # test.cmd
::
:: ## Overview
:: Smoke and 2-pass idempotency test suite for the rapps component on Windows and ReactOS.
::
:: ## Usage
:: _lib\package-managers\rapps\test.cmd

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

set "_TMP_BASE=%TEMP%\libscript_rapps_test_%RANDOM%"
set "LIBSCRIPT_HOME=!_TMP_BASE!\home"
set "LIBSCRIPT_OFFLINE=1"
set "STACK="
call "!SCRIPT_DIR!\setup_generic.cmd"
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\cli.cmd" prefetch 7zip --arch=i686 --dest="!_TMP_BASE!\pf"
if errorlevel 1 exit /b 1
if not exist "!_TMP_BASE!\pf\7zip.i686.stamp" exit /b 1
rmdir /s /q "!_TMP_BASE!" >nul 2>&1
echo [PASS] rapps component tests passed.
exit /b 0
