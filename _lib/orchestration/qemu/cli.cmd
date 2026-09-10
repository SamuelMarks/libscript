@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for QEMU on Windows.
::
:: ## Usage
:: Run `libscript orchestration/qemu [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=qemu"
call "%~dp0\..\..\_common\component_core.cmd" %*
