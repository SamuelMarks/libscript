@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for k0s on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up k0s.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
