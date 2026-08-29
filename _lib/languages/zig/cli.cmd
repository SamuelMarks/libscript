@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Zig on Windows.
::
:: ## Usage
:: Run `libscript languages/zig [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=zig"
call "%~dp0\..\..\_common\component_core.cmd" %*
