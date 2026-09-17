@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Elasticsearch on Windows.
::
:: ## Usage
:: Run `libscript search/elasticsearch [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=elasticsearch"
call "%~dp0\..\..\_common\component_core.cmd" %*
