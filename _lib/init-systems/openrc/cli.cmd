@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for OpenRC on Windows.
::
:: ## Usage
:: Run `libscript init-systems/openrc [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=openrc"
call "%~dp0\..\..\_common\component_core.cmd" %*
