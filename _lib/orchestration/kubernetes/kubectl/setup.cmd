@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for kubectl on Windows.
::
:: ## Usage
:: Routes to generic setup via `setup_base.cmd`.

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
