@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for C# on Windows.
::
:: ## Usage
:: Run `libscript languages/csharp [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=csharp"
call "%~dp0\..\..\_common\component_core.cmd" %*
