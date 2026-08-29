@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Go on Windows.
::
:: ## Usage
:: Run `libscript languages/go [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=go"
call "%~dp0\..\..\_common\component_core.cmd" %*
