@echo off
:: # uninstall.cmd
:: Uninstallation entry point for Vagrant on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
