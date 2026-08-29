@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Python on Windows.
::
:: ## Usage
:: Run `libscript languages/python [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=python"
call "%~dp0\..\..\_common\component_core.cmd" %*
