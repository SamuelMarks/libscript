@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for CC on Windows.
::
:: ## Usage
:: Run `libscript languages/cc [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=cc"
call "%~dp0\..\..\_common\component_core.cmd" %*
