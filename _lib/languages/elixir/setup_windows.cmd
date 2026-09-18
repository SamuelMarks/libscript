@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for elixir on Windows.
:: Prepares and configures elixir on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript elixir installation on Windows.

set "THIS_FILE=%~f0"

where elixir >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where choco >nul 2>&1
if errorlevel 1 (
    if exist "%ProgramData%\chocolatey\bin\choco.exe" (
        set "PATH=%ProgramData%\chocolatey\bin;!PATH!"
    ) else (
        echo Bootstrapping Chocolatey for Elixir...
        if not defined LIBSCRIPT_ROOT_DIR (
            for %%I in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
        )
        if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
            call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install choco
        ) else (
            powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; $t = Join-Path $env:TEMP 'install_choco.ps1'; (New-Object System.Net.WebClient).DownloadFile('https://community.chocolatey.org/install.ps1', $t); & $t; Remove-Item -Force -ErrorAction SilentlyContinue $t"
        )
        if exist "%ProgramData%\chocolatey\bin\choco.exe" (
            set "PATH=%ProgramData%\chocolatey\bin;!PATH!"
        )
    )
)

where choco >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing Elixir via choco...
    choco install -y elixir
    if not errorlevel 1 exit /b 0
)

echo Failed to install elixir.
exit /b 1
