@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for mamba on Windows.
:: Prepares and configures mamba on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript mamba installation on Windows.

set "THIS_FILE=%~f0"

where mamba >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "ARCH=64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/mamba-org/micromamba-releases/releases/download/2.9.0-0/micromamba-win-%ARCH%.exe"

echo Downloading micromamba (%ARCH%) from %URL%...
curl -sSL "%URL%" -o "%DEST_DIR%\micromamba.exe"
if errorlevel 1 (
    echo Failed to download micromamba.
    exit /b 1
)

copy /y "%DEST_DIR%\micromamba.exe" "%DEST_DIR%\mamba.exe" >nul

if exist "%DEST_DIR%\mamba.exe" (
    echo mamba installed successfully.
    exit /b 0
)

exit /b 1
