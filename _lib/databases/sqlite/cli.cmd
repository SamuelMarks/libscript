@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for SQLite on Windows.
::
:: ## Usage
:: Run `libscript databases/sqlite [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=sqlite"
call "%~dp0\..\..\_common\component_core.cmd" %*
