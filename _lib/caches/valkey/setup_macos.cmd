@echo off
:: # setup_macos.cmd
::
:: ## Overview
:: Provides structural alignment for macOS-specific setup logic on Windows environments.
:: It explicitly declares that a native Windows installation is not supported via this path.
:: 
:: ## Usage
:: Typically skipped; present for cross-platform repository consistency.

setlocal

:: This is a placeholder for the native Windows component setup.
:: By default, many tools rely on winget, choco, or scoop for installation on Windows.
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="ls" (
    echo [ls] Windows list support not implemented natively for this component.
    exit /b 0
)
if "%ACTION%"=="ls-remote" (
    echo [ls-remote] Windows ls-remote support not implemented natively for this component.
    exit /b 0
)
if "%ACTION%"=="use" (
    echo [use] Windows use support not implemented natively for this component.
    exit /b 0
)

echo Windows native installation not implemented.
exit /b 1
