@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Rust on Windows.
::
:: ## Usage
:: Run `libscript languages/rust [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=rust"
call "%~dp0\..\..\_common\component_core.cmd" %*
