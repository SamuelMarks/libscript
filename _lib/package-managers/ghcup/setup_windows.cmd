@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for ghcup on Windows.
:: Prepares and configures ghcup on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript ghcup installation on Windows.

set "THIS_FILE=%~f0"

where ghcup >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://downloads.haskell.org/~ghcup/x86_64-mingw64-ghcup.exe"

echo Downloading ghcup from %URL%...
curl -sSL "%URL%" -o "%DEST_DIR%\ghcup.exe"
if errorlevel 1 (
    echo Failed to download ghcup.
    exit /b 1
)

if exist "%DEST_DIR%\ghcup.exe" (
    echo ghcup installed successfully.
    exit /b 0
)

exit /b 1
