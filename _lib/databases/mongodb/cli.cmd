@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for MongoDB on Windows.
::
:: ## Usage
:: Run `libscript databases/mongodb [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=mongodb"
call "%~dp0\..\..\_common\component_core.cmd" %*
