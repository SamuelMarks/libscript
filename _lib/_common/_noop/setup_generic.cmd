@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Provides the generic, fallback installation logic for the `_noop` component on Windows.
:: It acts as a structural placeholder, explicitly declaring that native Windows
:: installation is not implemented natively for this stub component.
:: 
:: ## Usage
:: Typically called internally by `setup.cmd` when attempting generic setup on Windows.

setlocal

:: This is a placeholder for the native Windows component setup.
:: By default, many tools rely on winget, choco, or scoop for installation on Windows.

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
