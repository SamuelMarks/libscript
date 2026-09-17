@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Windows uninstallation script for Elasticsearch.

::
:: ## Usage
:: Call this script to trigger uninstallation for elasticsearch on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set ACTION=uninstall
call "%~dp0setup_generic.cmd" %*
