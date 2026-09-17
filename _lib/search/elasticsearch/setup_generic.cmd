@echo off
:: ## Overview
:: Windows setup script for Elasticsearch.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%ELASTICSEARCH_VERSION%"=="" set "ELASTICSEARCH_VERSION=7.17.21"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where elasticsearch >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] elasticsearch is already installed on the system.
        exit /b 0
    )
    set "TARGET_DIR=%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%"
    if exist "!TARGET_DIR!\bin\elasticsearch.bat" (
        echo [INFO] elasticsearch is already installed in !TARGET_DIR!.
        exit /b 0
    )
    where choco >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Installing elasticsearch via chocolatey...
        choco install elasticsearch -y
        exit /b 0
    )
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    rmdir /s /q "%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%" 2>nul
    exit /b 0
) else if "%ACTION%"=="test" (
    where elasticsearch >nul 2>&1 || (
        if exist "%LIBSCRIPT_HOME%\elasticsearch\%ELASTICSEARCH_VERSION%\bin\elasticsearch.bat" (
            echo [INFO] elasticsearch batch script verified.
            exit /b 0
        )
    )
    echo [INFO] elasticsearch test completed.
    exit /b 0
)

exit /b 0
