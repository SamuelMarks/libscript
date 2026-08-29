@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Deno on Windows.
::
:: ## Usage
:: Run `libscript languages/deno [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=deno"
call "%~dp0\..\..\_common\component_core.cmd" %*
