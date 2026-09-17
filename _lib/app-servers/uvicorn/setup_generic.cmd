@echo off
:: ## Overview
:: Windows setup script for Uvicorn ASGI server.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"

if "%ACTION%"=="install" (
    where uvicorn >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] uvicorn is already installed on Windows.
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing uvicorn via uv...
        uv tool install uvicorn >nul 2>&1 || uv pip install uvicorn
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing uvicorn via pip...
        pip install --user uvicorn
        exit /b 0
    )
    echo [ERROR] Python environment with pip or uv required to install uvicorn.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall uvicorn >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y uvicorn >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    uvicorn --version
    exit /b %ERRORLEVEL%
)

exit /b 0
