@echo off
:: ## Overview
:: Windows setup module for nodeenv.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%NODEENV_VERSION%"=="" set "NODEENV_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where nodeenv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] nodeenv is already installed on the system.
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing nodeenv via uv...
        uv tool install nodeenv >nul 2>&1 || uv pip install nodeenv
        exit /b 0
    )
    where pipx >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing nodeenv via pipx...
        pipx install nodeenv
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing nodeenv via pip...
        pip install --user nodeenv
        exit /b 0
    )
    echo [ERROR] Python environment with pip or uv is required to install nodeenv on Windows.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall nodeenv >nul 2>&1
    where pipx >nul 2>&1 && pipx uninstall nodeenv >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y nodeenv >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    nodeenv --version
    exit /b %ERRORLEVEL%
)

exit /b 0
