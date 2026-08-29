@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for CPP on Windows.
::
:: ## Usage
:: Run `libscript languages/cpp [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=cpp"
call "%~dp0\..\..\_common\component_core.cmd" %*
