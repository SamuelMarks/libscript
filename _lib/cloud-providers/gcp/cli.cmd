@echo off
:: # cli.cmd
::
:: ## Overview
:: GCP cloud provider component CLI entry point.
::
:: ## Usage
:: See `cli.sh` for primary usage instructions. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=gcp"
call "%~dp0\..\..\_common\component_core.cmd" %*
