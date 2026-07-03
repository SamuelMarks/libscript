@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for kubernetes-thw on Windows.
::
:: ## Usage
:: Run `libscript orchestration/kubernetes-thw [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=kubernetes-thw"
call "%~dp0\..\..\_common\component_core.cmd" %*
