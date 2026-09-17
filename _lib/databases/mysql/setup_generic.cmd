@echo off
:: ## Overview
:: Windows setup script for MySQL.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%MYSQL_VERSION%"=="" set "MYSQL_VERSION=8.4.11"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where mysql >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] mysql is already installed on the system.
        exit /b 0
    )
    where winget >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing MySQL via winget...
        winget install --id Oracle.MySQL -e --silent --accept-package-agreements --accept-source-agreements
        exit /b 0
    )
    where choco >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing MySQL via chocolatey...
        choco install mysql -y
        exit /b 0
    )
    echo [ERROR] Package manager (winget or choco) required to install MySQL on Windows.
    exit /b 1
) else if "%ACTION%"=="uninstall" (
    where winget >nul 2>&1 && winget uninstall --id Oracle.MySQL --silent
    where choco >nul 2>&1 && choco uninstall mysql -y
    exit /b 0
) else if "%ACTION%"=="test" (
    mysql --version
    exit /b %ERRORLEVEL%
)

exit /b 0
