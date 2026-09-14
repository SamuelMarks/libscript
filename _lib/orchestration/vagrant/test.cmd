@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite script for Vagrant on Windows.
::
:: ## Usage
:: Call this script to verify Vagrant functionality on Windows.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%USERPROFILE%\.local\bin" (
    set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)
if exist "C:\Program Files\Vagrant\bin" (
    set "PATH=C:\Program Files\Vagrant\bin;!PATH!"
)
if exist "C:\HashiCorp\Vagrant\bin" (
    set "PATH=C:\HashiCorp\Vagrant\bin;!PATH!"
)

where vagrant >nul 2>&1
if !errorlevel! equ 0 (
    vagrant --version
    exit /b 0
)
echo vagrant binary not found in PATH.
exit /b 1
