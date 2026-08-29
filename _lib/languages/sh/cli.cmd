@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for SH/Dash on Windows.
::
:: ## Usage
:: Run `libscript languages/sh [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=sh"
call "%~dp0\..\..\_common\component_core.cmd" %*
