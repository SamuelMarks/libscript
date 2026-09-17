@echo off
:: ## Overview
:: Windows setup script for Waitress WSGI server.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"

if "%ACTION%"=="install" (
    where waitress-serve >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] waitress is already installed on Windows.
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing waitress via uv...
        uv tool install waitress >nul 2>&1 || uv pip install waitress
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing waitress via pip...
        pip install --user waitress
        exit /b 0
    )
    echo [ERROR] Python environment with pip or uv required to install waitress.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall waitress >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y waitress >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    waitress-serve --help >nul 2>&1
    exit /b %ERRORLEVEL%
)

exit /b 0
