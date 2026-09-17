@echo off
:: ## Overview
:: Windows setup script for uWSGI.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%UWSGI_VERSION%"=="" set "UWSGI_VERSION=2.0.24"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where uwsgi >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] uwsgi is already installed on the system.
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing uwsgi via uv...
        uv tool install uwsgi >nul 2>&1 || uv pip install uwsgi
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing uwsgi via pip...
        pip install --user uwsgi
        exit /b 0
    )
    echo [ERROR] Python environment with pip or uv is required to install uwsgi.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall uwsgi >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y uwsgi >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    uwsgi --version
    exit /b %ERRORLEVEL%
)

exit /b 0
