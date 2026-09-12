@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation script for Vagrant on Windows.
::
:: ## Usage
:: Call this script to uninstall Vagrant on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
