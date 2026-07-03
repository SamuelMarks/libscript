@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Swift on Windows.
::
:: ## Usage
:: Run `libscript languages/swift [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=swift"
call "%~dp0\..\..\_common\component_core.cmd" %*
