@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation script for VirtualBox on Windows.
::
:: ## Usage
:: Call this script to uninstall VirtualBox on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
