@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for PHP on Windows.
::
:: ## Usage
:: Run `libscript languages/php [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=php"
call "%~dp0\..\..\_common\component_core.cmd" %*
