@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Kafka on Windows.
::
:: ## Usage
:: Run `libscript message-brokers/kafka [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=kafka"
call "%~dp0\..\..\_common\component_core.cmd" %*
