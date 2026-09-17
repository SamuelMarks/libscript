@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Generic uninstallation script for Exim on Windows.

::
:: ## Usage
:: Call this script to trigger uninstallation for exim on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_generic.cmd" %*
