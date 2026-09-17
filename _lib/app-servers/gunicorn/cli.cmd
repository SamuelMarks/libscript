@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Gunicorn on Windows.
::
:: ## Usage
:: Run `libscript app-servers/gunicorn [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=gunicorn"
call "%~dp0\..\..\_common\component_core.cmd" %*
