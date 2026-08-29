@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for PostgreSQL on Windows.
::
:: ## Usage
:: Run `libscript databases/postgres [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=postgres"
call "%~dp0\..\..\_common\component_core.cmd" %*
