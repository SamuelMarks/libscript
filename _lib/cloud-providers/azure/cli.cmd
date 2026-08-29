@echo off
:: # cli.cmd
::
:: ## Overview
:: Azure cloud provider component CLI entry point.
::
:: ## Usage
:: See `cli.sh` for primary usage instructions. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=azure"
call "%~dp0\..\..\_common\component_core.cmd" %*
