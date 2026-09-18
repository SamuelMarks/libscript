@echo off
:: ## Overview
:: Windows setup script for Gunicorn.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%GUNICORN_VERSION%"=="" set "GUNICORN_VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    echo [INFO] Gunicorn uses POSIX fork^(^). On Windows, installing Waitress and Uvicorn for native WSGI/ASGI execution...
    call "%~dp0\..\waitress\setup.cmd" install
    call "%~dp0\..\uvicorn\setup.cmd" install
    where gunicorn >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] gunicorn is also installed on the system.
        exit /b 0
    )
    where uv >nul 2>&1
    if not errorlevel 1 (
        uv pip install gunicorn >nul 2>&1
        exit /b 0
    )
    where pip >nul 2>&1
    if not errorlevel 1 (
        pip install --user gunicorn >nul 2>&1
        exit /b 0
    )
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    where uv >nul 2>&1 && uv tool uninstall gunicorn >nul 2>&1
    where pip >nul 2>&1 && pip uninstall -y gunicorn >nul 2>&1
    exit /b 0
) else if "%ACTION%"=="test" (
    gunicorn --version
    exit /b %ERRORLEVEL%
)

exit /b 0
