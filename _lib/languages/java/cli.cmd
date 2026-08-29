@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Java on Windows.
::
:: ## Usage
:: Run `libscript languages/java [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=java"
call "%~dp0\..\..\_common\component_core.cmd" %*
