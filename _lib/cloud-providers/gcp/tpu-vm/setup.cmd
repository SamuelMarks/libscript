@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for the GCP Cloud TPU VM component on Windows.
::
:: ## Usage
:: Invokes `setup_base.cmd` to route to the correct generic or OS-specific script.

setlocal EnableDelayedExpansion
if "%~1"=="--help" (
    echo Usage: %~nx0
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo See README.md for details.
    exit /b 0
)

call "%~dp0\..\..\_common\setup_base.cmd" %*
