@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Elixir on Windows.
::
:: ## Usage
:: Run `libscript languages/elixir [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=elixir"
call "%~dp0\..\..\_common\component_core.cmd" %*
