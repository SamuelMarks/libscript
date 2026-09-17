@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Exim on Windows.
::
:: ## Usage
:: Run `libscript utilities/exim [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=exim"
call "%~dp0\..\..\_common\component_core.cmd" %*
