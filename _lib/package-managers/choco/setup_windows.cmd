@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for choco on Windows.
:: Prepares and configures choco on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript choco installation on Windows.

set "THIS_FILE=%~f0"

where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo choco is already installed.
    exit /b 0
)

echo Installing Chocolatey via official PowerShell bootstrap...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; $t = Join-Path $env:TEMP 'install_choco.ps1'; (New-Object System.Net.WebClient).DownloadFile('https://community.chocolatey.org/install.ps1', $t); & $t; Remove-Item -Force -ErrorAction SilentlyContinue $t"

if exist "%ProgramData%\chocolatey\bin\choco.exe" (
    echo Chocolatey installed successfully.
    exit /b 0
)

where choco >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Failed to install Chocolatey.
exit /b 1
