@echo off
:: # uninstall_generic.cmd
::
:: ## Overview
:: Windows generic uninstallation script for Uvicorn.
::
:: ## Usage
:: Execute this script to uninstall Uvicorn.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where uv >nul 2>&1 && uv tool uninstall uvicorn >nul 2>&1
where pip >nul 2>&1 && pip uninstall -y uvicorn >nul 2>&1
exit /b 0
