@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for uWSGI on Windows.
::
:: ## Usage
:: Run `libscript app-servers/uwsgi [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=uwsgi"
call "%~dp0\..\..\_common\component_core.cmd" %*
