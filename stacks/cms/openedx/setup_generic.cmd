@echo off
:: ## Overview
:: Windows setup script for Open edX stack.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%OPENEDX_INSTALL_DIR%"=="" set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"

if "%ACTION%"=="install" (
    echo [INFO] Provisioning dependencies for Open edX on Windows...
    call "%~dp0\..\..\..\libscript.cmd" install python nodejs mysql mongodb redis meilisearch gunicorn exim nodeenv
    echo [INFO] Open edX Windows provisioning complete.
    exit /b 0
) else if "%ACTION%"=="test" (
    if exist "%OPENEDX_INSTALL_DIR%" (
        echo [INFO] Open edX directory exists at %OPENEDX_INSTALL_DIR%.
        exit /b 0
    ) else (
        echo [INFO] Open edX directory not created yet.
        exit /b 0
    )
) else if "%ACTION%"=="uninstall" (
    rmdir /s /q "%OPENEDX_INSTALL_DIR%" 2>nul
    exit /b 0
)

exit /b 0
