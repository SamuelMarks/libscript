@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the Jetstream component.
:: It handles basic help flags and delegates the core initialization logic
:: to the common `setup_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger the standard setup process for Jetstream on Windows.

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
