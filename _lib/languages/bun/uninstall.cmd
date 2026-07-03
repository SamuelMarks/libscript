@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Bun on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Bun.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
