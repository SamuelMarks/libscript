@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Provides fallback setup logic for components on Windows.
:: Resolves package dependencies via pkg_mgr or winget.
:: 
:: ## Usage
:: Typically called internally when attempting setup on Windows without a specific installer.

setlocal EnableDelayedExpansion
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

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    set "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\setup_base.cmd" %*
exit /b %ERRORLEVEL%
