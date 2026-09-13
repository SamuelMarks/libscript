@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for stack on Windows.
:: Downloads and installs the official Haskell Stack distribution.
::
:: ## Usage
:: Automatically invoked during libscript stack installation on Windows.

set "THIS_FILE=%~f0"

where stack >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/commercialhaskell/stack/releases/download/v3.11.1/stack-3.11.1-windows-x86_64.zip"
set "TEMP_ZIP=%TEMP%\stack.zip"

echo Downloading stack from %URL%...
curl.exe -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download stack.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\stack.exe" (
    echo stack installed successfully to %DEST_DIR%.
    exit /b 0
)

exit /b 1
