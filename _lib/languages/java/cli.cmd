@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Java on Windows.
::
:: ## Usage
:: Run `libscript languages/java [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=java"
call "%~dp0\..\..\_common\component_core.cmd" %*
