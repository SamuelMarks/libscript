@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for systemd on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up systemd.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
