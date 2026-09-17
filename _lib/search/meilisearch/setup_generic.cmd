@echo off
:: ## Overview
:: Windows setup script for Meilisearch.
::
:: ## Usage
:: Called internally by setup.cmd / cli.cmd.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set "ACTION=install"
if "%MEILISEARCH_VERSION%"=="" set "MEILISEARCH_VERSION=v1.36.0"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"

if "%ACTION%"=="install" (
    where meilisearch >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] meilisearch is already installed on the system.
        exit /b 0
    )
    set "TARGET_DIR=%LIBSCRIPT_HOME%\meilisearch\%MEILISEARCH_VERSION%\bin"
    if exist "!TARGET_DIR!\meilisearch.exe" (
        echo [INFO] meilisearch is already installed in !TARGET_DIR!.
        exit /b 0
    )
    if not exist "!TARGET_DIR!" mkdir "!TARGET_DIR!" >nul 2>&1
    set "BIN_URL=https://github.com/meilisearch/meilisearch/releases/download/%MEILISEARCH_VERSION%/meilisearch-windows-amd64.exe"
    echo [INFO] Downloading Meilisearch from !BIN_URL!...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '!BIN_URL!' -OutFile '!TARGET_DIR!\meilisearch.exe'"
    exit /b 0
) else if "%ACTION%"=="uninstall" (
    rmdir /s /q "%LIBSCRIPT_HOME%\meilisearch\%MEILISEARCH_VERSION%" 2>nul
    exit /b 0
) else if "%ACTION%"=="test" (
    meilisearch --version
    exit /b %ERRORLEVEL%
)

exit /b 0
