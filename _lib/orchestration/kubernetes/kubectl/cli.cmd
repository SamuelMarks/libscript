@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for kubectl on Windows.
::
:: ## Usage
:: Run `libscript orchestration/kubernetes/kubectl [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=kubectl"
call "%~dp0\..\..\_common\component_core.cmd" %*
