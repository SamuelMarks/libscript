@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Windows uninstallation wrapper for uWSGI.

::
:: ## Usage
:: Call this script to trigger uninstallation for uwsgi on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
