@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Provides a generic, cross-platform setup mechanism for the WooCommerce e-commerce platform stack.
:: Delegates to setup.cmd for Windows provisioning.
:: 
:: ## Usage
:: Execute this script to perform generic initialization steps.
set "THIS_FILE=%~f0"

if exist "%~dp0setup.cmd" (
    call "%~dp0setup.cmd" %*
    exit /b %ERRORLEVEL%
)

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] No suitable Windows setup executor found.
exit /b 1
