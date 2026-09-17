@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for MySQL on Windows.
::
:: ## Usage
:: Run `libscript databases/mysql [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=mysql"
call "%~dp0\..\..\_common\component_core.cmd" %*
