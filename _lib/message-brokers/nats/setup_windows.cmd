@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for nats on Windows.
:: Prepares and configures nats on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript nats installation on Windows.

set "THIS_FILE=%~f0"

where nats-server >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where nats >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/nats-io/nats-server/releases/download/v2.11.2/nats-server-v2.11.2-windows-%ARCH%.zip"
set "TEMP_ZIP=%TEMP%\nats.zip"

echo Downloading NATS server from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if not errorlevel 1 (
    tar -xf "%TEMP_ZIP%" -C "%TEMP%"
    for /r "%TEMP%\nats-server-v2.11.2-windows-%ARCH%" %%F in (nats-server.exe) do (
        if exist "%%F" copy /y "%%F" "%DEST_DIR%" >nul
    )
    del "%TEMP_ZIP%" >nul 2>&1
)

if exist "%DEST_DIR%\nats-server.exe" (
    echo NATS installed successfully to %DEST_DIR%.
    exit /b 0
)

echo NATS configured.
exit /b 0
