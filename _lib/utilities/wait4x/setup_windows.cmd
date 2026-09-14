@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for wait4x on Windows.
:: Prepares and configures wait4x on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript wait4x installation on Windows.

set "THIS_FILE=%~f0"

set "VERSION=%WAIT4X_VERSION%"
if "%VERSION%"=="" set "VERSION=v3.7.1"
if "%VERSION%"=="latest" set "VERSION=v3.7.1"

set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"

set "URL=https://github.com/wait4x/wait4x/releases/download/%VERSION%/wait4x-windows-%ARCH%.tar.gz"
set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "TEMP_TAR=%TEMP%\wait4x.tar.gz"

echo Downloading wait4x %VERSION% (%ARCH%) from %URL%...
curl -sSL "%URL%" -o "%TEMP_TAR%"
if errorlevel 1 (
    echo Failed to download wait4x.
    exit /b 1
)

tar -xzf "%TEMP_TAR%" -C "%DEST_DIR%"
del "%TEMP_TAR%" >nul 2>&1

if exist "%DEST_DIR%\wait4x.exe" (
    echo wait4x installed successfully to %DEST_DIR%.
    exit /b 0
)

echo Failed to install wait4x.
exit /b 1
