@echo off
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup entry point for uWSGI.

::
:: ## Usage
:: Call this script to trigger setup for uwsgi on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0setup_generic.cmd" %*
