@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for vcpkg on Windows.
:: Prepares and configures vcpkg on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript vcpkg installation on Windows.

set "THIS_FILE=%~f0"

where vcpkg >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

if exist "%DEST_DIR%\vcpkg.exe" exit /b 0

echo Downloading official vcpkg.exe from GitHub releases...
curl.exe -sSL "https://github.com/microsoft/vcpkg-tool/releases/latest/download/vcpkg.exe" -o "%DEST_DIR%\vcpkg.exe"
if errorlevel 1 (
    echo Failed to download vcpkg.exe.
    exit /b 1
)

if exist "%DEST_DIR%\vcpkg.exe" (
    echo vcpkg installed successfully.
    exit /b 0
)

echo Failed to install vcpkg.
exit /b 1
