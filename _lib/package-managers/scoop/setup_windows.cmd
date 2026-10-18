@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for scoop on Windows.
:: Prepares and configures scoop on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript scoop installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

where scoop >nul 2>&1
if %errorlevel% equ 0 (
    echo scoop is already installed.
    exit /b 0
)

echo Installing scoop via official PowerShell bootstrap...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ScoopInstaller/Install/master/install.ps1 -OutFile $env:TEMP\install_scoop.ps1; & $env:TEMP\install_scoop.ps1 -RunAsAdmin; Remove-Item $env:TEMP\install_scoop.ps1 -Force -ErrorAction SilentlyContinue"

if exist "%USERPROFILE%\scoop\shims\scoop.cmd" (
    echo scoop installed successfully.
    exit /b 0
)

where scoop >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Failed to install scoop.
exit /b 1
