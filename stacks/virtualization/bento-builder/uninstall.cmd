@echo off
:: # uninstall.cmd
:: Uninstallation entry point for Bento Builder stack on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\..\_lib\_common\uninstall_base.cmd" %*
