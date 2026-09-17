@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for nodeenv on Windows.
::
:: ## Usage
:: Run `libscript package-managers/nodeenv [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=nodeenv"
call "%~dp0\..\..\_common\component_core.cmd" %*
