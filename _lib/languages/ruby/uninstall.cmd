@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Ruby on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Ruby.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
