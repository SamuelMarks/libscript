@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for OpenRC on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up OpenRC.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
