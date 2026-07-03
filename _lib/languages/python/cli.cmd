@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Python on Windows.
::
:: ## Usage
:: Run `libscript languages/python [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=python"
call "%~dp0\..\..\_common\component_core.cmd" %*
