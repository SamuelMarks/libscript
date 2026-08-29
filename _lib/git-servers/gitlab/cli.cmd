@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for GitLab on Windows.
::
:: ## Usage
:: Run `libscript git-servers/gitlab [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=gitlab"
call "%~dp0\..\..\_common\component_core.cmd" %*
