@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for NATS on Windows.
::
:: ## Usage
:: Run `libscript message-brokers/nats [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=nats"
call "%~dp0\..\..\_common\component_core.cmd" %*
