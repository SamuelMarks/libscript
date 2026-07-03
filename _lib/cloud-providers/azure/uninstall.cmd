@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for the Azure cloud provider on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Azure configuration.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
