@echo off
:: # setup.cmd
::
:: ## Overview
:: Windows setup entry point for Uvicorn.

::
:: ## Usage
:: Call this script to trigger setup for uvicorn on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
