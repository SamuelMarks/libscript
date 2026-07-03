@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic Windows setup instructions for Rust.
::
:: ## Usage
:: Currently un-implemented and returns 1.

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
