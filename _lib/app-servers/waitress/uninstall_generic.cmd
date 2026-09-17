@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Windows generic uninstallation script for Waitress.
::
:: ## Usage
:: Execute this script to uninstall Waitress.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where uv >nul 2>&1 && uv tool uninstall waitress >nul 2>&1
where pip >nul 2>&1 && pip uninstall -y waitress >nul 2>&1
exit /b 0
