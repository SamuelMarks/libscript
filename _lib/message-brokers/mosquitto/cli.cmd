@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Mosquitto on Windows.
::
:: ## Usage
:: Run `libscript message-brokers/mosquitto [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=mosquitto"
call "%~dp0\..\..\_common\component_core.cmd" %*
