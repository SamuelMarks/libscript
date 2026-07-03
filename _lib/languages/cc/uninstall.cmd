@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for CC on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up CC.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
