@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Git server utils on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\_common\uninstall_base.cmd" %*
