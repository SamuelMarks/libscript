@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Git server utils on Windows.
::
:: ## Usage
:: Run `libscript git-servers/utils [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=utils"
call "%~dp0\..\_common\component_core.cmd" %*
