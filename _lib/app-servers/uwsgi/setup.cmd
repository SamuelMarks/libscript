@echo off
:: # setup.cmd
::
:: ## Overview
:: Windows setup entry point for uWSGI.
:: Delegates to shared `setup_base.cmd`.

::
:: ## Usage
:: Call this script to trigger setup for uwsgi on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
