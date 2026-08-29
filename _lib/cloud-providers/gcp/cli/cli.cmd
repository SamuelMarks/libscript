@echo off
:: # cli.cmd
::
:: ## Overview
:: GCP CLI component entry point for Windows.
::
:: ## Usage
:: See `cli.sh` for primary usage instructions. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=gcp-cli"
call "%~dp0\..\..\_common\component_core.cmd" %*
