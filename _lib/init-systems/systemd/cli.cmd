@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for systemd on Windows.
::
:: ## Usage
:: Run `libscript init-systems/systemd [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=systemd"
call "%~dp0\..\..\_common\component_core.cmd" %*
