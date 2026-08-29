@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Kotlin on Windows.
::
:: ## Usage
:: Run `libscript languages/kotlin [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=kotlin"
call "%~dp0\..\..\_common\component_core.cmd" %*
