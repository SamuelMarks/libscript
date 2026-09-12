@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation script for QEMU on Windows.
::
:: ## Usage
:: Call this script to uninstall QEMU on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
