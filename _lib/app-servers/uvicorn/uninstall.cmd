@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Windows uninstallation script for Uvicorn.

::
:: ## Usage
:: Call this script to trigger uninstallation for uvicorn on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set ACTION=uninstall
call "%~dp0setup_generic.cmd" %*
