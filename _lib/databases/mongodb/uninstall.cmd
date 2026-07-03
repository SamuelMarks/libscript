@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for MongoDB on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up MongoDB.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
