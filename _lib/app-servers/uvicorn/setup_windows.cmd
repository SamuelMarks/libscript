@echo off
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup entry point for Uvicorn.

::
:: ## Usage
:: Call this script to trigger setup for uvicorn on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0setup_generic.cmd" %*
