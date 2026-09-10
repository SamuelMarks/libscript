@echo off
:: # uninstall.cmd
:: Uninstallation entry point for VirtualBox on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
