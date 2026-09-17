@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Windows generic uninstallation script for hMailServer.
::
:: ## Usage
:: Execute this script to uninstall hMailServer.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where choco >nul 2>&1 && choco uninstall hmailserver -y
exit /b 0
