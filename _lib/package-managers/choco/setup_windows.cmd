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
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"

if exist "%ProgramData%\chocolatey\bin\choco.exe" (
    echo Chocolatey installed successfully.
    exit /b 0
)

where choco >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Failed to install Chocolatey.
exit /b 1
