@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for nuget on Windows.
:: Prepares and configures nuget on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript nuget installation on Windows.

set "THIS_FILE=%~f0"

where nuget >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Downloading nuget.exe from https://dist.nuget.org/win-x86-commandline/latest/nuget.exe...
curl -sSL "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -o "%DEST_DIR%/nuget.exe"
if errorlevel 1 (
    echo Failed to download nuget.exe.
    exit /b 1
)

if exist "%DEST_DIR%/nuget.exe" (
    echo nuget installed successfully to %DEST_DIR%.
    exit /b 0
)

exit /b 1
