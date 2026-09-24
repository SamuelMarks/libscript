@echo off
setlocal EnableDelayedExpansion
:: # setup_windows.cmd
::
:: ## Overview
:: Setup script for Hetzner CLI on Windows.
:: Installs official Hetzner Cloud CLI (hcloud) via winget.
::
:: ## Usage
:: Automatically invoked during libscript hetzner installation on Windows.

set "THIS_FILE=%~f0"

where hcloud >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Installing Hetzner Cloud CLI via winget...
winget install --id HetznerCloud.CLI --silent --accept-package-agreements --accept-source-agreements

where hcloud >nul 2>&1
if %errorlevel% equ 0 exit /b 0

for /d %%W in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\HetznerCloud.CLI*") do (
    if exist "%%W\hcloud.exe" (
        set "DEST_DIR=%USERPROFILE%\.libscript\hetzner\latest\bin"
        if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
        copy /y "%%W\hcloud.exe" "!DEST_DIR!\hcloud.exe" >nul 2>&1
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        copy /y "%%W\hcloud.exe" "%USERPROFILE%\.local\bin\hcloud.exe" >nul 2>&1
        exit /b 0
    )
)

exit /b 0
