@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Docker on Windows.
::
:: ## Usage
:: Run `libscript orchestration/docker [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=docker"
call "%~dp0\..\..\_common\component_core.cmd" %*
