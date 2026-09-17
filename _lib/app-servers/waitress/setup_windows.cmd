@echo off
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup entry point for Waitress.

::
:: ## Usage
:: Call this script to trigger setup for waitress on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0setup_generic.cmd" %*
