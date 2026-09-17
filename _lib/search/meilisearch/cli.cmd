@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Meilisearch on Windows.
::
:: ## Usage
:: Run `libscript search/meilisearch [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=meilisearch"
call "%~dp0\..\..\_common\component_core.cmd" %*
