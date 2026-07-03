@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for C on Windows.
::
:: ## Usage
:: Run `libscript languages/c [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=c"
call "%~dp0\..\..\_common\component_core.cmd" %*
