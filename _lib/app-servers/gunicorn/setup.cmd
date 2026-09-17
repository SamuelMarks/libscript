@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary Windows setup entry point for Gunicorn.
:: Delegates to the shared `setup_base.cmd`.

::
:: ## Usage
:: Call this script to trigger setup for gunicorn on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
