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
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=psmux"

set "ACTION=%~1"
if "%ACTION%"=="install" goto :delegate
if "%ACTION%"=="test" goto :delegate
if "%ACTION%"=="uninstall" goto :delegate
if "%ACTION%"=="remove" goto :delegate
if "%ACTION%"=="info" goto :delegate
if "%ACTION%"=="env" goto :delegate

set "LOG_CMD=%~dp0..\..\_common\log.cmd"

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
    if exist "%ProgramFiles%\psmux\psmux.cmd" set "PATH=%ProgramFiles%\psmux;!PATH!"
    if exist "%USERPROFILE%\.local\bin\psmux.cmd" set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)

where psmux >nul 2>nul
if %errorlevel% neq 0 (
    call "%LOG_CMD%" :log_error "psmux not found. Please ensure it is installed and in your PATH."
    exit /b 1
)

psmux %*
exit /b %errorlevel%

:delegate
call "%~dp0\..\..\_common\component_core.cmd" %*
exit /b %errorlevel%
