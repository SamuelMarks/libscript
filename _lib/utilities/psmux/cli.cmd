@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the psmux component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script directly to run the CLI functionality for the component.

setlocal EnableDelayedExpansion

set "LOG_CMD=%~dp0..\..\..\_common\log.cmd"

if "%~1"=="--help" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)

where psmux >nul 2>nul
if %errorlevel% neq 0 (
    call "%LOG_CMD%" :log_error "psmux not found. Please ensure it is installed and in your PATH."
    exit /b 1
)

psmux %*
exit /b %errorlevel%
