@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for RabbitMQ on Windows.
::
:: ## Usage
:: Run `libscript message-brokers/rabbitmq [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=rabbitmq"
call "%~dp0\..\..\_common\component_core.cmd" %*
