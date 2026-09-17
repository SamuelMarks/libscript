@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Waitress on Windows.
::
:: ## Usage
:: Run `libscript app-servers/waitress [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=waitress"
call "%~dp0\..\..\_common\component_core.cmd" %*
