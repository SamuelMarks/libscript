@echo off
:: ## Overview
:: Test suite for the kubernetes-thw component on Windows.
::
:: ## Usage
:: Execute this script to perform a component-specific test on Windows.

setlocal enabledelayedexpansion
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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\.."
)

where vagrant >nul 2>&1
if errorlevel 1 (
    echo [SKIP] Vagrant is not installed; skipping kubernetes-thw test on Windows.
    exit /b 0
)

echo [INFO] Running kubernetes-thw tests on Windows...
call "%SCRIPT_DIR%\ch2_jumpbox_only.cmd"
if errorlevel 1 exit /b !errorlevel!

echo [PASS] kubernetes-thw test completed.
exit /b 0
