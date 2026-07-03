@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Java on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Java.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
