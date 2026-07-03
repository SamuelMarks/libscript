@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for kubectl on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up kubectl.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
