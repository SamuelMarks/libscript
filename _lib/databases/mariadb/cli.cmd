@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for MariaDB on Windows.
::
:: ## Usage
:: Run `libscript databases/mariadb [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=mariadb"
call "%~dp0\..\..\_common\component_core.cmd" %*
