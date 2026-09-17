@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Generic uninstallation script for Meilisearch on Windows.

::
:: ## Usage
:: Call this script to trigger uninstallation for meilisearch on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_generic.cmd" %*
