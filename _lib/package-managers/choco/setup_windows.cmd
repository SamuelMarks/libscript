@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for choco on Windows.
:: Prepares and configures choco on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript choco installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

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
