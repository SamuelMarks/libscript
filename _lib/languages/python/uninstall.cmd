@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Python on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Python.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
