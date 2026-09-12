@echo off
:: ## Overview
:: Test suite for the kubernetes-thw component on Windows.
::
:: ## Usage
:: Execute this script to perform a component-specific test on Windows.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
