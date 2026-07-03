@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for CPP on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up CPP.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
