@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Node.js on Windows.
::
:: ## Usage
:: Run `libscript languages/nodejs [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=nodejs"
call "%~dp0\..\..\_common\component_core.cmd" %*
