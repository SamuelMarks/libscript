@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Provides the generic, fallback installation logic for the `_noop` component on Windows.
:: It acts as a structural placeholder that succeeds as a no-op.
:: 
:: ## Usage
:: Typically called internally by `setup.cmd` when attempting generic setup on Windows.

setlocal
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="ls" (
    exit /b 0
)
if "%ACTION%"=="ls-remote" (
    exit /b 0
)
if "%ACTION%"=="use" (
    exit /b 0
)
if "%ACTION%"=="install" (
    exit /b 0
)

exit /b 0
