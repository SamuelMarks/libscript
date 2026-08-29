@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for k0s on Windows.
::
:: ## Usage
:: Run `libscript orchestration/kubernetes-k0s [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=kubernetes-k0s"
call "%~dp0\..\..\_common\component_core.cmd" %*
