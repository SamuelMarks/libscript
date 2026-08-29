@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Python on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Python.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
