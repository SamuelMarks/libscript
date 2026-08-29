@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Fluent Bit on Windows.
::
:: ## Usage
:: Run `libscript logging/fluentbit [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=fluentbit"
call "%~dp0\..\..\_common\component_core.cmd" %*
