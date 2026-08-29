@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Bun on Windows.
::
:: ## Usage
:: Run `libscript languages/bun [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=bun"
call "%~dp0\..\..\_common\component_core.cmd" %*
