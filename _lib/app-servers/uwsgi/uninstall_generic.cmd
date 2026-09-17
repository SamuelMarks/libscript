@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Generic uninstallation script for uWSGI on Windows.

::
:: ## Usage
:: Call this script to trigger uninstallation for uwsgi on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_generic.cmd" %*
