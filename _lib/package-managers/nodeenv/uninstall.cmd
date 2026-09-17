@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Windows uninstallation wrapper for nodeenv.

::
:: ## Usage
:: Call this script to trigger uninstallation for nodeenv on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
