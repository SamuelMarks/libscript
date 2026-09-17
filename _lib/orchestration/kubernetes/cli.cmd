@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Kubernetes on Windows.
::
:: ## Usage
:: Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=kubernetes"
call "%~dp0\..\..\_common\component_core.cmd" %*
