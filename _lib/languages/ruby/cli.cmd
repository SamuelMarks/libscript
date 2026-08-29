@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Ruby on Windows.
::
:: ## Usage
:: Run `libscript languages/ruby [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=ruby"
call "%~dp0\..\..\_common\component_core.cmd" %*
