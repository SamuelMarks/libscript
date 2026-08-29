@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Gitea on Windows.
::
:: ## Usage
:: Run `libscript git-servers/gitea [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=gitea"
call "%~dp0\..\..\_common\component_core.cmd" %*
